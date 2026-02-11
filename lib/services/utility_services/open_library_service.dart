import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:library_ai/models/book_model.dart';

class OpenLibraryService {
  static const String _baseUrl = 'https://openlibrary.org/search.json';
  static const String _coverBaseUrl = 'https://covers.openlibrary.org/b/id';

  /// Cerca libri per categoria o query libera
  Future<List<Book>> fetchBooks(String query) async {
    final sanitizedQuery = query.replaceAll(' ', '+');

    // Ordina per rilevanza (default) e limita a 25 per non sovraccaricare
    final url = Uri.parse(
      '$_baseUrl?q=$sanitizedQuery&limit=25&fields=key,title,author_name,cover_i,ratings_average,ratings_count,number_of_pages_median,first_sentence,subject',
    );

    try {
      // --- REGOLA ETICA: USER-AGENT ---
      // Identifichiamo la tua app per non essere bloccati
      final headers = {
        'User-Agent':
            'MyLibraryApp/1.0 (tuaemail@example.com)', // Metti la tua mail vera o finta, basta che ci sia
        'Accept': 'application/json',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> docs = data['docs'] ?? [];

        // Mappiamo e filtriamo
        return docs.map((json) => _mapOpenLibraryToBook(json)).where((book) {
          // FILTRO QUALITÀ "ARCHITECT":
          // 1. Deve avere la copertina
          // 2. Il titolo non deve essere troppo generico (es. "Works")
          // 3. Scartiamo se ha 0 voti (spesso sono edizioni fantasma)
          return book.thumbnailUrl.isNotEmpty &&
              !book.title.toLowerCase().contains("collection") &&
              (book.ratingsCount ?? 0) > 0;
        }).toList();
      } else {
        print("Errore OpenLibrary: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Eccezione OpenLibrary: $e");
      return [];
    }
  }

  Book _mapOpenLibraryToBook(Map<String, dynamic> json) {
    // Gestione Copertina Alta Qualità
    String coverUrl = "";
    if (json['cover_i'] != null) {
      coverUrl = '$_coverBaseUrl/${json['cover_i']}-L.jpg';
    }

    // Gestione Autore
    String author = "Autore Sconosciuto";
    if (json['author_name'] != null &&
        (json['author_name'] as List).isNotEmpty) {
      author = json['author_name'][0];
    }

    // Gestione Descrizione
    String description = "";
    if (json['first_sentence'] != null &&
        (json['first_sentence'] as List).isNotEmpty) {
      description = json['first_sentence'][0];
    } else {
      // Fallback: se non c'è la prima frase, usiamo i soggetti come descrizione
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
      id: safeId, // <--- Usiamo l'ID sicuro
      title: json['title'] ?? "Senza Titolo",
      author: author,
      description: description,
      thumbnailUrl: coverUrl,
      pageCount: json['number_of_pages_median'],
      averageRating: (json['ratings_average'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: json['ratings_count'] ?? 0,
    );
  }
}
