import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/book_widgets/book_model.dart';

class OpenLibraryService {
  static const String _baseUrl = 'https://openlibrary.org/search.json';
  static const String _coverBaseUrl = 'https://covers.openlibrary.org/b/id';

  /// Cerca libri con supporto per Ordinamento
  /// [sortBy]: 'relevance', 'new', 'old', 'rating_desc' (Client side)
  Future<List<Book>> fetchBooks(
    String query, {
    String sortBy = 'relevance',
  }) async {
    final sanitizedQuery = query.replaceAll(' ', '+');

    // Costruiamo l'URL base
    // Nota: 'sort' parameter di OpenLib supporta 'new', 'old', 'random'.
    String apiSortParam = '';
    if (sortBy == 'new') apiSortParam = '&sort=new';
    if (sortBy == 'old') apiSortParam = '&sort=old';

    // Richiediamo più campi per poter ordinare lato client se necessario
    final url = Uri.parse(
      '$_baseUrl?q=$sanitizedQuery$apiSortParam&limit=25&fields=key,title,author_name,cover_i,ratings_average,ratings_count,number_of_pages_median,first_sentence,subject',
    );

    try {
      final headers = {
        'User-Agent': 'CultureVault/1.0 (dev@culturevault.app)',
        'Accept': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];

        // 1. Mappatura
        List<Book> books = docs
            .map((json) => _mapOpenLibraryToBook(json))
            .where(
              (book) =>
                  // Filtri Qualità Architect
                  book.thumbnailUrl.isNotEmpty &&
                  !book.title.toLowerCase().contains("collection") &&
                  (book.ratingsCount ?? 0) > 0,
            )
            .toList();

        // 2. Sorting Lato Client (Dove l'API fallisce o non supporta)
        if (sortBy == 'rating_desc') {
          // Ordina per voto medio decrescente
          books.sort((a, b) {
            // Null safety check: if null, treat as 0.0
            final double ratingA = (a.averageRating ?? 0).toDouble();
            final double ratingB = (b.averageRating ?? 0).toDouble();
            return ratingB.compareTo(ratingA); // Decrescente (B compareTo A)
          });
        } else if (sortBy == 'reviews_desc') {
          // Ordina per numero recensioni decrescente
          books.sort((a, b) {
            // Null safety check: if null, treat as 0
            final int countA = a.ratingsCount ?? 0;
            final int countB = b.ratingsCount ?? 0;
            return countB.compareTo(countA); // Decrescente
          });
        }

        return books;
      } else {
        // Gestione errore (opzionale: loggare lo status code)
        return [];
      }
    } catch (e) {
      print("Eccezione OpenLibrary: $e");
      return [];
    }
  }

  // --- MAPPATURA ---
  Book _mapOpenLibraryToBook(Map<String, dynamic> json) {
    String coverUrl = "";
    if (json['cover_i'] != null) {
      coverUrl = '$_coverBaseUrl/${json['cover_i']}-L.jpg';
    }

    String author = "Autore Sconosciuto";
    if (json['author_name'] != null &&
        (json['author_name'] as List).isNotEmpty) {
      author = json['author_name'][0];
    }

    String description = "";
    if (json['first_sentence'] != null &&
        (json['first_sentence'] as List).isNotEmpty) {
      description = json['first_sentence'][0];
    } else {
      if (json['subject'] != null) {
        description =
            "Argomenti: ${(json['subject'] as List).take(3).join(", ")}...";
      } else {
        description = "Nessuna descrizione disponibile.";
      }
    }

    final rawId = json['key'] ?? DateTime.now().toString();
    // Sanitize ID per Firestore (rimuovi slash che creano sottocollezioni)
    final safeId = rawId.toString().replaceAll('/', '_');

    return Book(
      id: safeId,
      title: json['title'] ?? "Senza Titolo",
      author: author,
      description: description,
      thumbnailUrl: coverUrl,
      pageCount: json['number_of_pages_median'],
      // Parsing sicuro per double e int
      averageRating: (json['ratings_average'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: json['ratings_count'] ?? 0,
    );
  }
}
