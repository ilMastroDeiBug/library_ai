import 'dart:async';
import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/app_mode.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/services/utility_services/language_service.dart';

// Use Cases
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/domain/use_cases/actor_use_cases.dart';

// Pages
import '../../Pages/book_detail_page.dart';
import '../../Pages/movie_detail_page.dart';
import '../../Pages/actor_detail_page.dart';

class SearchResultTile extends StatelessWidget {
  final dynamic item;
  final AppMode mode;

  const SearchResultTile({super.key, required this.item, required this.mode});

  @override
  Widget build(BuildContext context) {
    String title = "";
    String subtitle = "";
    String imageUrl = "";
    IconData defaultIcon = Icons.movie;
    VoidCallback onTap = () {};

    // Estrazione Dati
    if (item is Book) {
      title = item.title;
      subtitle = item.author;
      imageUrl = item.thumbnailUrl;
      defaultIcon = Icons.book;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailPage(book: item)),
      );
    } else if (item is Movie) {
      title = item.title;
      subtitle = item.releaseDate.isNotEmpty
          ? "Film • ${item.releaseDate.split('-')[0]}"
          : "Film";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.movie_creation_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is TvSeries) {
      title = item.name;
      subtitle = item.firstAirDate.isNotEmpty
          ? "Serie TV • ${item.firstAirDate.split('-')[0]}"
          : "Serie TV";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.live_tv_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is CastMember) {
      // GESTIONE ATTORI
      title = item.name;
      subtitle = item.character;
      imageUrl = item.fullProfileUrl;
      defaultIcon = Icons.person;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActorDetailPage(actorId: item.id)),
      );
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // LOCANDINA / FOTO PROFILO
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 70,
                      height: 105,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholder(defaultIcon),
                    )
                  : _buildPlaceholder(defaultIcon),
            ),
            const SizedBox(width: 16),

            // TESTI
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ICONA FRECCIA / PLAY
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                item is CastMember
                    ? Icons.arrow_forward_ios_rounded
                    : (mode == AppMode.books
                          ? Icons.menu_book_rounded
                          : Icons.play_circle_outline_rounded),
                size: item is CastMember ? 18 : 32,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 70,
      height: 105,
      color: Colors.white.withOpacity(0.05),
      child: Center(child: Icon(icon, color: Colors.white24, size: 30)),
    );
  }
}

class UniversalSearchDelegate extends SearchDelegate {
  final AppMode mode;

  UniversalSearchDelegate({required this.mode});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = Colors.orangeAccent;

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
    if (mode == AppMode.books) {
      return _buildMessage(
        Icons.auto_stories_rounded,
        "Ricerca disabilitata.\nIl Vault dei Libri è in arrivo!",
      );
    }

    return _DebouncedSearchList(
      query: query,
      mode: mode,
      closeDelegate: (result) => close(context, result),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (mode == AppMode.books) {
      return _buildMessage(
        Icons.auto_stories_rounded,
        "Ricerca disabilitata.\nIl Vault dei Libri è in arrivo!",
      );
    }

    return _DebouncedSearchList(
      query: query,
      mode: mode,
      closeDelegate: (result) => close(context, result),
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
  int _searchType = 0; // 0 = Media (Film/Serie), 1 = Attori

  final LanguageService _languageService = sl<LanguageService>();

  @override
  void initState() {
    super.initState();
    _languageService.addListener(_handleLanguageChanged);
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
    if (currentQuery.length < 3) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
          _lastSearchedQuery = "";
        });
      }
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(currentQuery);
    });
  }

  Future<void> _performSearch(String queryStr) async {
    final requestKey =
        '$queryStr::${_languageService.currentLanguage}::$_searchType';

    if (requestKey == _lastSearchedQuery) {
      setState(() => _isLoading = false);
      return;
    }

    _lastSearchedQuery = requestKey;
    List<dynamic> fetchResults = [];

    try {
      if (_searchType == 0) {
        // Cerca Film & Serie in parallelo
        final responses = await Future.wait([
          sl<SearchMoviesUseCase>().call(queryStr),
          sl<SearchTvSeriesUseCase>().call(queryStr),
        ]);

        // Unisce i risultati
        List<dynamic> combinedResults = [...responses[0], ...responses[1]];

        // Ordina i risultati combinati basandosi sulla popolarità
        combinedResults.sort((a, b) {
          // Utilizziamo un fallback a 0.0 per evitare crash
          // Richiede che a.popularity e b.popularity siano implementati nelle Entity
          double popA = 0.0;
          double popB = 0.0;

          if (a is Movie || a is TvSeries) popA = a.popularity ?? 0.0;
          if (b is Movie || b is TvSeries) popB = b.popularity ?? 0.0;

          return popB.compareTo(popA);
        });

        fetchResults = combinedResults;
      } else {
        // Cerca Attori
        fetchResults = await sl<SearchActorsUseCase>().call(queryStr);
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
    _languageService.removeListener(_handleLanguageChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _handleLanguageChanged() {
    _lastSearchedQuery = "";
    _queueSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          _buildToggleButtons(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(0, "Film & Serie TV")),
          Expanded(child: _buildTabButton(1, "Attori")),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _searchType == index;
    return GestureDetector(
      onTap: () {
        if (_searchType != index) {
          setState(() {
            _searchType = index;
            _lastSearchedQuery = ""; // Forza nuova ricerca
          });
          _queueSearch();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orangeAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.query.trim().length < 3) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.05),
            ),
            const SizedBox(height: 16),
            Text(
              "Cerca ${_searchType == 0 ? 'Film o Serie TV' : 'Attori'}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.orangeAccent,
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          "Nessun risultato trovato",
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return SearchResultTile(item: _results[index], mode: widget.mode);
      },
    );
  }
}
