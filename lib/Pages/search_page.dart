import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../google_books_service.dart';
import 'book_detail_page.dart';

class BookSearchDelegate extends SearchDelegate {
  final GoogleBooksService _booksService = GoogleBooksService();

  // Cambiamo il testo "Cerca" nella barra
  @override
  String get searchFieldLabel => 'Titolo, Autore o ISBN...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    // Personalizziamo la barra per adattarla al tema scuro "Culture OS"
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF232526),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF232526),
        iconTheme: IconThemeData(color: Colors.cyanAccent),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.cyanAccent,
        selectionColor: Colors.cyanAccent,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  // Azioni a destra (La "X" per cancellare)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () {
          query = ''; // Pulisce il testo
          showSuggestions(context); // Rimoa i suggerimenti
        },
      ),
    ];
  }

  // Azione a sinistra (Freccia indietro)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
      onPressed: () => close(context, null), // Chiude la ricerca
    );
  }

  // --- I RISULTATI DELLA RICERCA ---
  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text("Scrivi qualcosa...", style: TextStyle(color: Colors.grey)),
      );
    }

    return FutureBuilder<List<Book>>(
      future: _booksService.searchBooks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 60, color: Colors.grey),
                const SizedBox(height: 10),
                Text(
                  "Nessun libro trovato per '$query'",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final books = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              color: Colors.white.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          book.thumbnailUrl,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 50,
                          color: Colors.grey[800],
                          child: const Icon(Icons.book, color: Colors.white),
                        ),
                ),
                title: Text(
                  book.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  book.author,
                  style: const TextStyle(color: Colors.cyanAccent),
                  maxLines: 1,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
                onTap: () {
                  // Apre la pagina di dettaglio
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailPage(book: book),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- SUGGERIMENTI (Mentre scrivi o prima di scrivere) ---
  @override
  Widget buildSuggestions(BuildContext context) {
    // Qui potremmo mostrare la cronologia recente in futuro.
    // Per ora mostriamo un invito all'azione.
    return Container(
      color: const Color(0xFF232526),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_search,
              size: 80,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 10),
            const Text(
              "Cerca il tuo prossimo libro",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              "Prova '1984', 'Stephen King' o un ISBN",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
