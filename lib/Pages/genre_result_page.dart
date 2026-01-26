import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../google_books_service.dart';
import '../models/book_card.dart';

class GenreResultPage extends StatefulWidget {
  final String categoryName; // Es. "Horror" (per l'utente)
  final String categoryId; // Es. "horror" (per Google)

  const GenreResultPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<GenreResultPage> createState() => _GenreResultPageState();
}

class _GenreResultPageState extends State<GenreResultPage> {
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    // Chiamiamo il servizio usando l'ID passato dalla pagina precedente
    _booksFuture = GoogleBooksService().fetchBooksByCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232526),
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF232526),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Errore: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nessun libro trovato",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final books = snapshot.data!;

          // Usiamo una GRIGLIA per mostrare tanti risultati
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 libri per riga
              childAspectRatio: 0.6, // Verticali
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCard(book: books[index]);
            },
          );
        },
      ),
    );
  }
}
