import 'dart:async';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/models/app_mode.dart';

// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';

// Widget
import '../models/search_widgets/search_result_tile.dart';

class UniversalSearchDelegate extends SearchDelegate {
  final AppMode mode;

  UniversalSearchDelegate({required this.mode});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = Colors.orangeAccent; // TEMA CINESHARE

    return theme.copyWith(
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 18,
        ),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
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
          icon: const Icon(Icons.clear_rounded, color: Colors.white54),
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
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // 🔒 BLOCCO LIBRI: Se siamo in modalità libri, mostriamo subito il Coming Soon
    if (mode == AppMode.books) {
      return _buildMessage(
        Icons.auto_stories_rounded,
        "Ricerca disabilitata.\nIl Vault dei Libri è in arrivo!",
      );
    }

    if (query.trim().length < 3) {
      return _buildInitialSuggestions();
    }

    return _DebouncedSearchList(
      query: query,
      mode: mode,
      closeDelegate: (result) => close(context, result),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // 🔒 BLOCCO LIBRI: Sicurezza extra per evitare che l'utente forzi l'invio
    if (mode == AppMode.books) {
      return _buildMessage(
        Icons.auto_stories_rounded,
        "Ricerca disabilitata.\nIl Vault dei Libri è in arrivo!",
      );
    }

    if (query.trim().length < 3) {
      return _buildMessage(Icons.keyboard, "Digita almeno 3 caratteri...");
    }

    return _DebouncedSearchList(
      query: query,
      mode: mode,
      closeDelegate: (result) => close(context, result),
    );
  }

  Widget _buildInitialSuggestions() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == AppMode.books
                  ? Icons.auto_stories_rounded
                  : Icons.movie_filter_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 16),
            Text(
              mode == AppMode.books
                  ? "Cerca nel Vault dei Libri"
                  : "Cerca Film, Serie o Registi",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(IconData icon, String text) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 15),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- GESTORE DEBOUNCE E LISTA ---
class _DebouncedSearchList extends StatefulWidget {
  final String query;
  final AppMode mode;
  final Function(dynamic) closeDelegate;

  const _DebouncedSearchList({
    required this.query,
    required this.mode,
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

  void _queueSearch() {
    final currentQuery = widget.query.trim();
    if (currentQuery.length < 3) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() => _isLoading = true);

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
        // 🔒 BLOCCO LIBRI: Il UseCase dei libri NON viene più chiamato
        fetchResults = [];
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
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 50),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orangeAccent,
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty && _lastSearchedQuery.isNotEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 10),
              Text(
                "Nessun risultato per '${widget.query}'",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black, // Sfondo NERO dietro la lista
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        physics: const BouncingScrollPhysics(),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          return SearchResultTile(item: _results[index], mode: widget.mode);
        },
      ),
    );
  }
}
