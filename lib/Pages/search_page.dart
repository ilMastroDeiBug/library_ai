import 'dart:async'; // <-- IMPORTANTE PER IL DEBOUNCER
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/models/app_mode.dart';

// Entities
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';

// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';

// Pages
import 'package:library_ai/pages/book_detail_page.dart';
import 'package:library_ai/pages/movie_detail_page.dart';

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
  Widget buildSuggestions(BuildContext context) {
    // Mentre l'utente digita, mostriamo la versione "Leggera" (solo testo)
    if (query.trim().length < 3) {
      return _buildInitialSuggestions();
    }

    return _DebouncedSearchList(
      query: query,
      mode: mode,
      showImages: false, // <-- NIENTE COPERTINE DURANTE LA DIGITAZIONE
      closeDelegate: (result) => close(context, result),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Quando l'utente preme "Invio", mostriamo la versione "Pesante" (con locandine)
    if (query.trim().length < 3) {
      return _buildMessage(Icons.keyboard, "Digita almeno 3 caratteri...");
    }

    return _DebouncedSearchList(
      query: query,
      mode: mode,
      showImages: true, // <-- MOSTRA COPERTINE SOLO NEI RISULTATI FINALI
      closeDelegate: (result) => close(context, result),
    );
  }

  // --- UI HELPER ---
  Widget _buildInitialSuggestions() {
    return Container(
      color: const Color(0xFF0F0F10),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == AppMode.books
                  ? Icons.auto_stories
                  : Icons.movie_creation_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 16),
            Text(
              mode == AppMode.books
                  ? "Cerca Libri nel Vault"
                  : "Cerca Film e Serie TV",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
              ),
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

// --- CLASSE WIDGET SEPARATA PER GESTIRE IL DEBOUNCE E LA UI ---

class _DebouncedSearchList extends StatefulWidget {
  final String query;
  final AppMode mode;
  final bool showImages;
  final Function(dynamic) closeDelegate;

  const _DebouncedSearchList({
    required this.query,
    required this.mode,
    required this.showImages,
    required this.closeDelegate,
  });

  @override
  State<_DebouncedSearchList> createState() => _DebouncedSearchListState();
}

class _DebouncedSearchListState extends State<_DebouncedSearchList> {
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _lastSearchedQuery = "";

  @override
  void initState() {
    super.initState();
    _queueSearch();
  }

  @override
  void didUpdateWidget(covariant _DebouncedSearchList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _queueSearch();
    }
  }

  // Metodo che previene lo spam di chiamate API
  void _queueSearch() {
    final currentQuery = widget.query.trim();
    if (currentQuery.length < 3) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() => _isLoading = true);

    // Aspetta mezzo secondo prima di chiamare l'API
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(currentQuery);
    });
  }

  Future<void> _performSearch(String queryStr) async {
    if (queryStr == _lastSearchedQuery) {
      setState(() => _isLoading = false);
      return;
    }

    _lastSearchedQuery = queryStr;
    List<dynamic> fetchResults = [];

    try {
      if (widget.mode == AppMode.books) {
        fetchResults = await sl<SearchBooksUseCase>().call(queryStr);
      } else {
        final responses = await Future.wait([
          sl<SearchMoviesUseCase>().call(queryStr),
          sl<SearchTvSeriesUseCase>().call(queryStr),
        ]);
        fetchResults = [...responses[0], ...responses[1]];
      }
    } catch (e) {
      debugPrint("Search Error: $e");
    }

    if (mounted) {
      setState(() {
        _results = fetchResults;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Spegniamo il timer quando usciamo
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.mode == AppMode.books
                ? Colors.orangeAccent
                : Colors.cyanAccent,
          ),
        ),
      );
    }

    if (_results.isEmpty && _lastSearchedQuery.isNotEmpty) {
      return Container(
        color: const Color(0xFF0F0F10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 10),
              Text(
                "Nessun risultato per '${widget.query}'",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return _buildItemRow(context, item);
      },
    );
  }

  Widget _buildItemRow(BuildContext context, dynamic item) {
    String title = "";
    String subtitle = "";
    String imageUrl = "";
    IconData defaultIcon = Icons.movie;

    if (item is Book) {
      title = item.title;
      subtitle = item.author;
      imageUrl = item.thumbnailUrl;
      defaultIcon = Icons.book;
    } else if (item is Movie) {
      title = item.title;
      subtitle = item.releaseDate.isNotEmpty
          ? "Film (${item.releaseDate.split('-')[0]})"
          : "Film";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.movie_outlined;
    } else if (item is TvSeries) {
      title = item.name;
      subtitle = item.firstAirDate.isNotEmpty
          ? "Serie TV (${item.firstAirDate.split('-')[0]})"
          : "Serie TV";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.tv_outlined;
    }

    VoidCallback handleTap = () {
      // Navigazione
      if (item is Book) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(book: item)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
        );
      }
    };

    // --- UI LEGGERA (Solo Titoli) ---
    if (!widget.showImages) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        leading: Icon(
          defaultIcon,
          color: widget.mode == AppMode.books
              ? Colors.orangeAccent
              : Colors.cyanAccent,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.white24,
        ),
        onTap: handleTap,
      );
    }

    // --- UI PESANTE (Con Immagini, come avevi fatto tu) ---
    return GestureDetector(
      onTap: handleTap,
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
                          (widget.mode == AppMode.books
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
}
