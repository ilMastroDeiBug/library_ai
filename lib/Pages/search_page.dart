import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/models/app_mode.dart';

// Entities
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart'; // Importa TvSeries

// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart'; // Importa

// Pages
import 'package:library_ai/Pages/book_detail_page.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';

class UniversalSearchDelegate extends SearchDelegate {
  final AppMode mode;

  UniversalSearchDelegate({required this.mode});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = mode == AppMode.books
        ? Colors.orangeAccent
        : Colors.cyanAccent;

    return theme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0F10),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F0F10),
        elevation: 0,
        iconTheme: IconThemeData(color: activeColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: activeColor,
        selectionColor: activeColor.withOpacity(0.3),
        selectionHandleColor: activeColor,
      ),
    );
  }

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

    // LOGICA DI RICERCA MISTA
    Future<List<dynamic>> searchFuture;

    if (mode == AppMode.books) {
      searchFuture = sl<SearchBooksUseCase>().call(query);
    } else {
      // In modalità Cinema, cerchiamo sia Film che Serie
      // (Potresti usare Future.wait per parallelizzare)
      searchFuture = _searchCinemaContent(query);
    }

    return FutureBuilder<List<dynamic>>(
      future: searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: mode == AppMode.books
                  ? Colors.orangeAccent
                  : Colors.cyanAccent,
            ),
          );
        }
        if (snapshot.hasError) {
          return _buildMessage(Icons.error_outline, "Errore di connessione.");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildMessage(
            Icons.search_off,
            "Nessun risultato per '$query'",
          );
        }

        final results = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          physics: const BouncingScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return _buildResultTile(context, results[index]);
          },
        );
      },
    );
  }

  // Helper per cercare sia Film che Serie
  Future<List<dynamic>> _searchCinemaContent(String query) async {
    final movies = await sl<SearchMoviesUseCase>().call(query);
    final series = await sl<SearchTvSeriesUseCase>().call(query);
    return [...movies, ...series];
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
              mode == AppMode.books
                  ? Icons.menu_book_rounded
                  : Icons.movie_filter_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 10),
            Text(
              mode == AppMode.books
                  ? "Cerca Libri nel Vault"
                  : "Cerca Film e Serie TV",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, dynamic item) {
    String title = "";
    String subtitle = "";
    String imageUrl = "";
    VoidCallback onTap = () {};

    // GESTIONE POLIMORFICA (Book, Movie, TvSeries)
    if (item is Book) {
      title = item.title;
      subtitle = item.author;
      imageUrl = item.thumbnailUrl;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailPage(book: item)),
      );
    } else if (item is Movie) {
      title = item.title;
      subtitle = item.releaseDate.isNotEmpty
          ? "Film (${item.releaseDate.split('-')[0]})"
          : "Film";
      imageUrl = item.fullPosterUrl;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is TvSeries) {
      title = item.name;
      subtitle = item.firstAirDate.isNotEmpty
          ? "Serie TV (${item.firstAirDate.split('-')[0]})"
          : "Serie TV";
      imageUrl = item.fullPosterUrl;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 75,
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.broken_image,
                    size: 20,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          (mode == AppMode.books
                                  ? Colors.orangeAccent
                                  : Colors.cyanAccent)
                              .withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
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
