import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/book.dart'; // Assicurati che il path sia giusto

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // INCOLLA QUI LA TUA CHIAVE API
  static const String _apiKey = "AIzaSyCTtFz_xjeahtxCeQYhCrOHRFguCT_mDJY";

  // --- FUNZIONE FILTRO ELITE ---
  Future<List<Book>> fetchBooksByCategory(String category) async {
    final url = Uri.parse(
      '$_baseUrl?q=subject:$category&maxResults=40&langRestrict=it&orderBy=relevance&key=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        // CORREZIONE 1: Usa 'fromApi'
        List<Book> allBooks = items.map((json) => Book.fromApi(json)).toList();

        // 2. FILTRAGGIO
        var eliteBooks = allBooks.where((book) {
          // averageRating è un getter, quindi va bene chiamarlo, ma controlliamo > 0
          bool hasRating = book.rating > 0;
          bool hasVotes = book.ratingsCount > 0;
          bool hasImage = book.thumbnailUrl.isNotEmpty;

          return hasRating && hasVotes && hasImage;
        }).toList();

        // 3. ORDINAMENTO
        eliteBooks.sort((a, b) {
          return b.rating.compareTo(a.rating);
        });

        return eliteBooks.take(15).toList();
      } else {
        print("Errore API Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Errore API Google Books: $e");
      return [];
    }
  }

  // Funzione di ricerca specifica
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    final sanitizedQuery = query.replaceAll(' ', '+');
    final url = Uri.parse(
      '$_baseUrl?q=$sanitizedQuery&maxResults=20&langRestrict=it&key=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        // CORREZIONE 1: Usa 'fromApi'
        return items.map((json) => Book.fromApi(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Errore Ricerca: $e");
      return [];
    }
  }
}
