// ... imports ...
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';

import 'package:flutter/material.dart';
// 1. Dependency Injection

// 2. Use Cases
// 3. Entities (Se hai spostato Book in domain/entities usa quello, altrimenti il path vecchio)
import '../../domain/entities/book.dart';
// import '../models/book_widgets/book_model.dart'; // <-- USA QUESTO SE NON HAI SPOSTATO IL FILE BOOK

// 4. Widgets
import '../models/search_widgets/search_result_tile.dart';

class BookSearchDelegate extends SearchDelegate {
  // --- STILE DELLA BARRA DI RICERCA ---
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0F10),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F10),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.orangeAccent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          decoration: TextDecoration.none,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.orangeAccent,
        selectionColor: Colors.orangeAccent,
        selectionHandleColor: Colors.orangeAccent,
      ),
    );
  }

  // 1. AZIONI A DESTRA (La "X" per cancellare)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  // 2. AZIONE A SINISTRA (Freccia indietro)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      onPressed: () => close(context, null),
    );
  }

  // 3. I RISULTATI (Quando premi invio)
  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().length < 3) {
      return _buildMessage(Icons.keyboard, "Digita almeno 3 caratteri...");
    }

    return FutureBuilder<List<Book>>(
      // CHIAMATA CLEAN ARCHITECTURE:
      future: sl<SearchBooksUseCase>().call(query),

      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        // Errore
        if (snapshot.hasError) {
          return _buildMessage(Icons.error_outline, "Errore di connessione.");
        }

        // Nessun dato
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildMessage(
            Icons.search_off,
            "Nessun libro trovato per '$query'",
          );
        }

        // Successo
        final books = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: books.length,
          itemBuilder: (context, index) {
            return SearchResultTile(book: books[index]);
          },
        );
      },
    );
  }

  // 4. I SUGGERIMENTI (Mentre scrivi)
  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F10),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_search,
              size: 80,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 10),
            const Text(
              "Cerca nel Vault",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER PER MESSAGGI ---
  Widget _buildMessage(IconData icon, String text) {
    return Container(
      color: const Color(0xFF0F0F10),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
