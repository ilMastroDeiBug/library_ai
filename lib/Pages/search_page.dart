import 'package:flutter/material.dart';
import '/models/book_widgets/book_model.dart';
import '../services/utility_services/open_library_service.dart';
import '../models/search_widgets/search_result_tile.dart';

class BookSearchDelegate extends SearchDelegate {
  final OpenLibraryService _booksService = OpenLibraryService();

  // Variabili di stato per i filtri (resettati a ogni nuova istanza)
  String _sortBy =
      'relevance'; // 'relevance', 'new', 'old', 'random' (OpenLib supporta questi)
  // Nota: OpenLib non supporta facilmente il sorting per "rating" via API diretta di ricerca,
  // ma possiamo simulare o usare i parametri che hanno.

  @override
  String get searchFieldLabel => 'Titolo, Autore...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0F10),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F10),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.orangeAccent), // Brand Color
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

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      // TASTO FILTRI
      IconButton(
        icon: const Icon(Icons.tune),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: const Color(0xFF1E1E1E),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => _buildFilterSheet(ctx),
          );
        },
      ),
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

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().length < 3) {
      return _buildMessage(Icons.keyboard, "Digita almeno 3 caratteri...");
    }

    // Passiamo anche il sorting al service (dovrai aggiornare il service, vedi sotto)
    return FutureBuilder<List<Book>>(
      future: _booksService.fetchBooks(query, sortBy: _sortBy),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          return _buildMessage(Icons.error_outline, "Errore di connessione.");
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildMessage(
            Icons.search_off,
            "Nessun libro trovato per '$query'",
          );
        }

        final books = snapshot.data!;

        // ESEMPIO DI SORTING LATO CLIENT (Se l'API non lo fa bene)
        // Se volessimo ordinare A-Z qui:
        // if (_sortBy == 'title_az') {
        //   books.sort((a, b) => a.title.compareTo(b.title));
        // }

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
            const SizedBox(height: 5),
            Text(
              "Filtro attivo: ${_getSortLabel(_sortBy)}",
              style: TextStyle(
                color: Colors.orangeAccent.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET FILTRI (Sheet) ---
  Widget _buildFilterSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ORDINA RISULTATI",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildFilterOption(context, "Rilevanza", 'relevance'),
          _buildFilterOption(context, "Pubblicazione (Recenti)", 'new'),
          _buildFilterOption(context, "Pubblicazione (Vecchi)", 'old'),
          // OpenLibrary API sort param 'random' esiste, 'rating' è sperimentale/non affidabile in search
          // Ma possiamo mettere dei placeholder
          const Divider(color: Colors.white24),
          const Text(
            "FILTRI (Prossimamente)",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              Chip(
                label: const Text("Sci-Fi"),
                backgroundColor: Colors.white10,
              ),
              Chip(
                label: const Text("Thriller"),
                backgroundColor: Colors.white10,
              ),
              Chip(
                label: const Text("History"),
                backgroundColor: Colors.white10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.orangeAccent : Colors.white70,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.orangeAccent)
          : null,
      onTap: () {
        _sortBy = value;
        Navigator.pop(context); // Chiudi sheet
        showResults(context); // Ricarica risultati
      },
    );
  }

  String _getSortLabel(String value) {
    switch (value) {
      case 'new':
        return 'Più Recenti';
      case 'old':
        return 'Più Vecchi';
      default:
        return 'Rilevanza';
    }
  }

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
