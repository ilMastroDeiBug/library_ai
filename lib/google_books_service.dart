import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // Funzione per cercare libri per categoria (es. "fantasy", "science fiction")
  Future<List<Book>> fetchBooksByCategory(String category) async {
    // Costruiamo l'URL: cerchiamo per "subject" (genere)
    final url = Uri.parse(
      '$_baseUrl?q=subject:$category&maxResults=40&langRestrict=it',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        // Trasforma ogni elemento della lista JSON in un oggetto Book
        return items.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Errore nel caricamento dei libri');
      }
    } catch (e) {
      print("Errore API Google Books: $e");
      return []; // Se fallisce, restituisce una lista vuota per non rompere l'app
    }
  }

  // Funzione di ricerca specifica (Titolo, Autore, ISBN)
  Future<List<Book>> searchBooks(String query) async {
    if (query.isEmpty) return [];

    // Convertiamo gli spazi in '+' per l'URL
    final sanitizedQuery = query.replaceAll(' ', '+');

    // Usiamo 'q=$sanitizedQuery' generico: Google è abbastanza intelligente
    // da capire se è un titolo, un autore o un ISBN da solo.
    final url = Uri.parse(
      '$_baseUrl?q=$sanitizedQuery&maxResults=40&langRestrict=it',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items.map((json) => Book.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Errore Ricerca: $e");
      return [];
    }
  }
}
