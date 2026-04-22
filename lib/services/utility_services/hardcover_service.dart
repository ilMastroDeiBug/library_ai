import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:library_ai/secrets.dart'; // Assicurati che il path sia corretto
import '../../domain/entities/book.dart';

/// Service Enterprise per l'integrazione con Hardcover GraphQL API.
/// Dati puri, zero over-fetching, copertine in alta qualità e sorting ibrido.
class HardcoverService {
  // L'endpoint Hasura/GraphQL di Hardcover
  static const String _endpoint = 'https://platform.hardcover.app/v1/graphql';

  // Chiave API / JWT Token protetto tramite classe Secrets
  // NOTA: Se il token che hai copiato inizia già con "Bearer ", assicurati
  // che in Secrets.hardcoverApiKey non ci sia scritto due volte.
  static const String _apiKey = Secrets.apiKey;

  // Timeout di sicurezza (10 secondi)
  static const Duration _timeout = Duration(seconds: 10);

  // ===========================================================================
  // 1. LE QUERY GRAPHQL (Il vero potere di Hasura)
  // ===========================================================================

  /// Query di Ricerca: Cerca per titolo ignorando il case (_ilike)
  static const String _searchQuery = '''
    query SearchBooks(\$q: String!, \$limit: Int!) {
      books(
        where: { title: { _ilike: \$q } }
        limit: \$limit
        order_by: { users_read_count: desc }
      ) {
        id
        title
        description
        pages
        cached_rating
        users_read_count
        image {
          url
        }
        contributions(limit: 1) {
          author {
            name
          }
        }
      }
    }
  ''';

  /// Query per Categoria: Cerca match nel titolo o nella descrizione
  /// Usata per emulare la ricerca per genere
  static const String _categoryQuery = '''
    query BooksByCategory(\$category: String!, \$limit: Int!) {
      books(
        where: { 
          _or: [
            { title: { _ilike: \$category } },
            { description: { _ilike: \$category } }
          ]
        }
        limit: \$limit
        order_by: { cached_rating: desc, users_read_count: desc }
      ) {
        id
        title
        description
        pages
        cached_rating
        users_read_count
        image {
          url
        }
        contributions(limit: 1) {
          author {
            name
          }
        }
      }
    }
  ''';

  /// Fallback Trending: I libri più letti in assoluto
  static const String _trendingQuery = '''
    query TrendingBooks(\$limit: Int!) {
      books(
        limit: \$limit
        order_by: { users_read_count: desc }
      ) {
        id
        title
        description
        pages
        cached_rating
        users_read_count
        image {
          url
        }
        contributions(limit: 1) {
          author {
            name
          }
        }
      }
    }
  ''';

  // ===========================================================================
  // 2. METODI PUBBLICI PER IL REPOSITORY
  // ===========================================================================

  /// Ricerca testuale libera (Usata dalla Search Bar)
  Future<List<Book>> searchBooks(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];

    // In Hasura (SQL), il simbolo % funziona da wildcard per _ilike
    final String formattedQuery = '%${query.trim()}%';

    return await _fetchAdvanced(
      graphqlQuery: _searchQuery,
      variables: {'q': formattedQuery, 'limit': 40},
      sortBy: 'relevance', // Su Hardcover gestiamo l'ordine base via GraphQL
    );
  }

  /// Esplorazione per Categoria/Genere (Usata dalla pagina Explore)
  Future<List<Book>> fetchBooksByCategory(
    String category, {
    int page = 1,
    String sortBy = 'rating_desc',
  }) async {
    // Categorie Speciali: Trending
    if (category.toLowerCase() == 'trending' ||
        category.toLowerCase() == 'popular') {
      return await _fetchAdvanced(
        graphqlQuery: _trendingQuery,
        variables: {'limit': 40},
        sortBy: 'reviews_desc',
      );
    }

    // Ricerca per Genere (usiamo una stringa parziale per beccare i tag/descrizioni)
    final String formattedCategory = '%${category.trim()}%';

    return await _fetchAdvanced(
      graphqlQuery: _categoryQuery,
      variables: {'category': formattedCategory, 'limit': 40},
      sortBy: sortBy,
    );
  }

  // ===========================================================================
  // 3. MOTORE DI ESECUZIONE GRAPHQL (IL CORE)
  // ===========================================================================

  /// Invia il payload GraphQL al server Hardcover e applica filtri/sorting
  Future<List<Book>> _fetchAdvanced({
    required String graphqlQuery,
    required Map<String, dynamic> variables,
    String sortBy = 'relevance',
  }) async {
    try {
      // Prepariamo l'Header. GraphQL usa il Bearer token standard.
      // Se _apiKey contiene già "Bearer ", non lo aggiungiamo due volte.
      final String authHeader = _apiKey.startsWith('Bearer ')
          ? _apiKey
          : 'Bearer $_apiKey';

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': authHeader,
              'User-Agent': 'CineShareApp/1.0',
            },
            body: jsonEncode({'query': graphqlQuery, 'variables': variables}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Controllo errori nativi di GraphQL
        if (data.containsKey('errors')) {
          print("❌ ERRORE GRAPHQL HASURA: ${data['errors']}");
          return [];
        }

        final List<dynamic> booksData = data['data']['books'] ?? [];

        // Mappatura
        List<Book> books = booksData
            .map((json) => _mapHardcoverToBook(json))
            .toList();

        // Filtro Qualità: Via i libri senza copertina o palesemente vuoti
        books = books
            .where(
              (b) => b.thumbnailUrl.isNotEmpty && b.title != 'Senza Titolo',
            )
            .toList();

        // HYBRID SORTING ENGINE (Ordinamento in RAM lato Dart)
        books = _applyClientSideSorting(books, sortBy);

        return books;
      } else {
        print(
          "❌ ERRORE SERVER HARDCOVER: ${response.statusCode} - ${response.body}",
        );
        return [];
      }
    } on TimeoutException {
      print("❌ TIMEOUT: Il server Hardcover non ha risposto in tempo.");
      return [];
    } on SocketException {
      print("❌ ERRORE DI RETE: Controlla la tua connessione internet.");
      return [];
    } catch (e) {
      print("❌ ECCEZIONE SCONOSCIUTA HARDCOVER: $e");
      return [];
    }
  }

  // ===========================================================================
  // 4. ALGORITMI DI ORDINAMENTO E MAPPATURA
  // ===========================================================================

  /// Applica l'ordinamento avanzato sui dati estratti (Hybrid Sorting)
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
    // Per 'relevance', GraphQL (Hasura) restituisce i dati già nell'ordine
    // deciso all'interno della query (order_by: { users_read_count: desc })
    return books;
  }

  /// Estrae i dati navigando l'albero GraphQL in modo Type-Safe
  Book _mapHardcoverToBook(Map<String, dynamic> json) {
    // Navigazione sicura per le relazioni GraphQL (contributions -> author)
    String authorName = 'Autore Sconosciuto';
    if (json['contributions'] != null &&
        (json['contributions'] as List).isNotEmpty) {
      final contribution = json['contributions'][0];
      if (contribution['author'] != null &&
          contribution['author']['name'] != null) {
        authorName = contribution['author']['name'].toString().trim();
      }
    }

    // Estrazione Immagine
    String imageUrl = '';
    if (json['image'] != null && json['image']['url'] != null) {
      imageUrl = json['image']['url'].toString();
    }

    // Hardcover a volte ha HTML residuo (raro, ma preveniamo)
    String rawDesc = json['description'] ?? 'Nessuna sinossi disponibile.';
    String cleanDesc = _cleanHtml(rawDesc);

    // Dati statistici
    final double rating = (json['cached_rating'] as num?)?.toDouble() ?? 0.0;
    final int ratingsCount = (json['users_read_count'] as num?)?.toInt() ?? 0;
    final int pages = (json['pages'] as num?)?.toInt() ?? 0;

    // L'ID univoco di Hardcover
    final String id = json['id']?.toString() ?? DateTime.now().toString();

    return Book(
      id: id,
      title: json['title']?.toString() ?? 'Senza Titolo',
      author: authorName,
      description: cleanDesc,
      thumbnailUrl: imageUrl,
      pageCount: pages,
      rating: rating,
      ratingsCount: ratingsCount,
    );
  }

  // ===========================================================================
  // 5. UTILITIES DI SANITIZZAZIONE
  // ===========================================================================

  /// Rimuove residui HTML se presenti nelle descrizioni utente
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
}
