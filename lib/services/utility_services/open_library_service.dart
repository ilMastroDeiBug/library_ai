import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/book.dart'; // Assicurati che il path sia giusto

class OpenLibraryService {
  static const String _baseUrl = 'https://openlibrary.org/search.json';
  static const String _coverBaseUrl = 'https://covers.openlibrary.org/b/id';

  Future<List<Book>> fetchBooks(
    String query, {
    String sortBy = 'relevance',
  }) async {
    final sanitizedQuery = query.replaceAll(' ', '+');

    String apiSortParam = '';
    if (sortBy == 'new') apiSortParam = '&sort=new';
    if (sortBy == 'old') apiSortParam = '&sort=old';

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

        List<Book> books = docs
            .map((json) => _mapOpenLibraryToBook(json))
            .where(
              (book) =>
                  book.thumbnailUrl.isNotEmpty &&
                  !book.title.toLowerCase().contains("collection") &&
                  book.ratingsCount > 0,
            )
            .toList();

        // Sorting Client Side
        if (sortBy == 'rating_desc') {
          books.sort((a, b) => b.rating.compareTo(a.rating));
        } else if (sortBy == 'reviews_desc') {
          books.sort((a, b) => b.ratingsCount.compareTo(a.ratingsCount));
        }

        return books;
      } else {
        return [];
      }
    } catch (e) {
      print("Eccezione OpenLibrary: $e");
      return [];
    }
  }

  // --- MAPPATURA CORRETTA ---
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
    final safeId = rawId.toString().replaceAll('/', '_');

    return Book(
      id: safeId,
      title: json['title'] ?? "Senza Titolo",
      author: author,
      description: description,
      thumbnailUrl: coverUrl,
      pageCount: json['number_of_pages_median'],

      // CORREZIONE 2: Parametro 'rating' invece di 'averageRating'
      rating: (json['ratings_average'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: json['ratings_count'] ?? 0,
    );
  }
}
