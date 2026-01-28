import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // INCOLLA QUI LA TUA CHIAVE API
  static const String _apiKey = "AIzaSyCTtFz_xjeahtxCeQYhCrOHRFguCT_mDJY";

  // Funzione per cercare libri per categoria
  Future<List<Book>> fetchBooksByCategory(String category) async {
    // Aggiungiamo &key=$_apiKey alla fine
    final url = Uri.parse(
      '$_baseUrl?q=$category&maxResults=20&langRestrict=it&orderBy=relevance&key=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items.map((json) => Book.fromJson(json)).toList();
      } else {
        // Se vedi 429 qui, vuol dire che anche con la chiave stai esagerando, ma è difficile.
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
    // Aggiungiamo &key=$_apiKey anche qui
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
