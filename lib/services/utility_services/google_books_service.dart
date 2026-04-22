import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:library_ai/secrets.dart';
import '../../domain/entities/book.dart';

/// Service Enterprise per l'integrazione con Google Books API.
/// Gestisce Query avanzate, Sanitizzazione Dati, Upscaling Immagini e Sorting Ibrido.
class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // Chiave API protetta tramite classe Secrets
  static const String _apiKey = Secrets.booksApiKey;

  // Timeout di sicurezza per evitare blocchi della UI (10 secondi)
  static const Duration _timeout = Duration(seconds: 10);

  // ===========================================================================
  // 1. METODI PUBBLICI PER IL REPOSITORY
  // ===========================================================================

  /// Ricerca testuale libera (Usata dalla Search Bar)
  Future<List<Book>> searchBooks(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];

    return await _fetchAdvanced(query: query, sortBy: 'relevance', page: page);
  }

  /// Esplorazione per Categoria/Genere (Usata dalla pagina Explore)
  Future<List<Book>> fetchBooksByCategory(
    String category, {
    int page = 1,
    String sortBy = 'rating_desc',
  }) async {
    if (category.toLowerCase() == 'trending' ||
        category.toLowerCase() == 'popular') {
      return await _fetchAdvanced(
        query: '*',
        sortBy: 'reviews_desc',
        page: page,
      );
    }

    // FIX CATEGORIE: Traduciamo la categoria italiana nel subject ufficiale di Google
    final String apiSubject = _translateCategoryToGoogleSubject(category);

    return await _fetchAdvanced(
      query: 'subject:"$apiSubject"',
      sortBy: sortBy,
      page: page,
    );
  }

  // ===========================================================================
  // IL TRADUTTORE DEI GENERI LETTERARI
  // ===========================================================================
  String _translateCategoryToGoogleSubject(String italianCategory) {
    final cat = italianCategory.toLowerCase().trim();
    switch (cat) {
      case 'fantascienza':
        return 'Science Fiction';
      case 'giallo':
      case 'gialli':
      case 'thriller':
        return 'Mystery';
      case 'fantasy':
        return 'Fantasy';
      case 'romanzo':
      case 'romanzi':
        return 'Fiction';
      case 'horror':
        return 'Horror';
      case 'storico':
        return 'History';
      case 'biografia':
        return 'Biography';
      case 'fumetti':
      case 'manga':
        return 'Comics';
      case 'scienza':
        return 'Science';
      case 'filosofia':
        return 'Philosophy';
      default:
        return italianCategory; // Se non c'è, proviamo a passarla così com'è
    }
  }

  // ===========================================================================
  // 2. MOTORE DI RICERCA AVANZATO (IL CORE)
  // ===========================================================================

  Future<List<Book>> _fetchAdvanced({
    required String query,
    String sortBy = 'relevance',
    int page = 1,
    int maxResults = 40,
  }) async {
    final int startIndex = (page - 1) * maxResults;
    String apiOrderBy = (sortBy == 'new') ? 'newest' : 'relevance';

    // LA PRIMA MANDATA: Il parametro langRestrict nativo
    final Uri url = Uri.parse(
      '$_baseUrl?q=${Uri.encodeComponent(query)}'
      '&langRestrict=it' // <-- Chiediamo gentilmente l'italiano
      '&orderBy=$apiOrderBy'
      '&maxResults=$maxResults'
      '&startIndex=$startIndex'
      '&printType=books'
      '&key=$_apiKey',
    );

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'CineShareApp/1.0 (Mobile)',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        // LA SECONDA MANDATA (Il Filtro Spietato):
        // Uccidiamo i risultati inglesi che Google cerca di infilarci di nascosto
        List<Book> books = items
            .where((json) {
              final volumeInfo = json['volumeInfo'] ?? {};
              final lang =
                  volumeInfo['language']?.toString().toLowerCase() ?? '';
              return lang == 'it'; // <-- Se non è 'it', fuori.
            })
            .map((json) => _mapGoogleToBook(json))
            .where(
              (b) => b.thumbnailUrl.isNotEmpty && b.title != 'Senza Titolo',
            )
            .toList();

        books = _applyClientSideSorting(books, sortBy);

        return books;
      } else {
        print(
          "Google Books API Error: ${response.statusCode} - ${response.body}",
        );
        return [];
      }
    } on TimeoutException {
      print("Google Books API Timeout: I server di Google sono lenti.");
      return [];
    } on SocketException {
      print("Google Books API Network Error: Nessuna connessione internet.");
      return [];
    } catch (e) {
      print("Google Books API Eccezione sconosciuta: $e");
      return [];
    }
  }

  // ===========================================================================
  // 3. ALGORITMI DI ORDINAMENTO E MAPPATURA
  // ===========================================================================

  List<Book> _applyClientSideSorting(List<Book> books, String sortBy) {
    if (sortBy == 'rating_desc') {
      books.sort((a, b) {
        int ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare == 0) {
          return b.ratingsCount.compareTo(a.ratingsCount);
        }
        return ratingCompare;
      });
    } else if (sortBy == 'reviews_desc') {
      books.sort((a, b) => b.ratingsCount.compareTo(a.ratingsCount));
    }
    return books;
  }

  Book _mapGoogleToBook(Map<String, dynamic> json) {
    final Map<String, dynamic> volumeInfo = json['volumeInfo'] ?? {};

    final String title = volumeInfo['title'] ?? 'Senza Titolo';
    final List<dynamic> authorsRaw = volumeInfo['authors'] ?? [];
    final String author = authorsRaw.isNotEmpty
        ? authorsRaw.first.toString()
        : 'Autore Sconosciuto';

    String rawDescription = volumeInfo['description'] ?? '';
    if (rawDescription.isEmpty) {
      rawDescription =
          volumeInfo['subtitle'] ??
          'Nessuna sinossi disponibile per questa edizione.';
    }
    final String cleanDescription = _cleanHtml(rawDescription);

    String coverUrl = '';
    if (volumeInfo['imageLinks'] != null) {
      coverUrl =
          volumeInfo['imageLinks']['thumbnail'] ??
          volumeInfo['imageLinks']['smallThumbnail'] ??
          '';
      coverUrl = _upgradeThumbnail(coverUrl);
    }

    final double rating =
        (volumeInfo['averageRating'] as num?)?.toDouble() ?? 0.0;
    final int ratingsCount = (volumeInfo['ratingsCount'] as num?)?.toInt() ?? 0;
    final int pageCount = (volumeInfo['pageCount'] as num?)?.toInt() ?? 0;

    final String id =
        json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    return Book(
      id: id,
      title: title,
      author: author,
      description: cleanDescription,
      thumbnailUrl: coverUrl,
      pageCount: pageCount,
      rating: rating,
      ratingsCount: ratingsCount,
    );
  }

  // ===========================================================================
  // 4. UTILITIES DI SANITIZZAZIONE
  // ===========================================================================

  String _cleanHtml(String htmlString) {
    String parsed = htmlString.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    parsed = parsed.replaceAll(RegExp(r'</p>'), '\n\n');

    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    parsed = parsed.replaceAll(exp, '');

    parsed = parsed
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    return parsed.trim();
  }

  String _upgradeThumbnail(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;

    String betterUrl = originalUrl;

    if (betterUrl.startsWith('http:')) {
      betterUrl = betterUrl.replaceFirst('http:', 'https:');
    }

    betterUrl = betterUrl.replaceAll('&edge=curl', '');

    if (betterUrl.contains('zoom=1')) {
      betterUrl = betterUrl.replaceAll('zoom=1', 'zoom=2');
    } else if (!betterUrl.contains('zoom=')) {
      betterUrl += '&zoom=2';
    }

    return betterUrl;
  }
}
