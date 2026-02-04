import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // INCOLLA QUI LA TUA CHIAVE API
  static const String _apiKey = "AIzaSyCTtFz_xjeahtxCeQYhCrOHRFguCT_mDJY";

  // --- FUNZIONE FILTRO ELITE ---
  Future<List<Book>> fetchBooksByCategory(String category) async {
    // 1. CHIEDIAMO IL MASSIMO (40) PER AVERE PIÙ SCELTA
    final url = Uri.parse(
      '$_baseUrl?q=subject:$category&maxResults=40&langRestrict=it&orderBy=relevance&key=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        // Convertiamo tutto in oggetti Book
        List<Book> allBooks = items.map((json) => Book.fromJson(json)).toList();

        // 2. FILTRAGGIO (Buttiamo la spazzatura)
        var eliteBooks = allBooks.where((book) {
          // Deve avere un voto medio valido
          bool hasRating = book.averageRating != null;
          // Deve avere almeno qualche voto (es. > 0) per essere credibile
          bool hasVotes = (book.ratingsCount ?? 0) > 0;
          // Deve avere la copertina
          bool hasImage = book.thumbnailUrl.isNotEmpty;

          return hasRating && hasVotes && hasImage;
        }).toList();

        // 3. ORDINAMENTO (Dal voto più alto al più basso)
        eliteBooks.sort((a, b) {
          return b.averageRating!.compareTo(a.averageRating!);
        });

        // 4. SELEZIONE (Prendiamo i migliori 15)
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

  // Funzione di ricerca specifica (Questa la lasciamo standard, l'utente sa cosa cerca)
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
        return items.map((json) => Book.fromJson(json)).toList();
      } else {
        print("Errore API Ricerca Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Errore Ricerca: $e");
      return [];
    }
  }
}
