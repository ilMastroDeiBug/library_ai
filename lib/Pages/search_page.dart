import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../domain/entities/book.dart';
import '../domain/entities/movie.dart';
import '../domain/entities/tv_series.dart';
import '../models/app_mode.dart';
import '../models/movie_widget/cast_model.dart';
import '../injection_container.dart';
import '../services/utility_services/language_service.dart';

// Use Cases
import '../domain/use_cases/movie_use_cases.dart';
import '../domain/use_cases/tv_series_use_cases.dart';
import '../domain/use_cases/actor_use_cases.dart';

// Pages
import 'book_detail_page.dart';
import 'movie_detail_page.dart';
import 'actor_detail_page.dart';
import 'package:library_ai/l10n/app_localizations.dart';

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
          ? "${AppLocalizations.of(context)!.movies} • ${item.releaseDate.split('-')[0]}"
          : AppLocalizations.of(context)!.movies;
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.movie_creation_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is TvSeries) {
      title = item.name;
      subtitle = item.firstAirDate.isNotEmpty
          ? "${AppLocalizations.of(context)!.tvSeries} • ${item.firstAirDate.split('-')[0]}"
          : AppLocalizations.of(context)!.tvSeries;
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
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 70,
                      height: 105,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 70,
                        height: 105,
                        color: Colors.white.withOpacity(0.05),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
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
        AppLocalizations.of(context)!.searchBooksDisabled,
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
        AppLocalizations.of(context)!.searchBooksDisabled,
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

  StreamSubscription<List<Movie>>? _movieSearchSubscription;
  StreamSubscription<List<TvSeries>>? _tvSearchSubscription;
  StreamSubscription<List<CastMember>>? _actorSearchSubscription;

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

    _movieSearchSubscription?.cancel();
    _tvSearchSubscription?.cancel();
    _actorSearchSubscription?.cancel();

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(currentQuery);
    });
  }

  void _performSearch(String queryStr) {
    final requestKey =
        '$queryStr::${_languageService.currentLanguage}::$_searchType';

    if (requestKey == _lastSearchedQuery) {
      setState(() => _isLoading = false);
      return;
    }

    _lastSearchedQuery = requestKey;

    if (_searchType == 0) {
      _listenToMediaSearch(queryStr);
    } else {
      _listenToActorSearch(queryStr);
    }
  }

  void _listenToMediaSearch(String queryStr) {
    List<Movie> latestMovies = [];
    List<TvSeries> latestTv = [];
    var hasMovieEmission = false;
    var hasTvEmission = false;

    // Funzione interna per combinare e ordinare i risultati dei due Stream
    void publishCombinedResults() {
      final combinedResults = <dynamic>[...latestMovies, ...latestTv];

      combinedResults.sort((a, b) {
        // Estrazione sicura della popolarità per evitare crash a runtime
        double popA = 0.0;
        double popB = 0.0;

        if (a is Movie || a is TvSeries) {
          popA = (a.popularity as num?)?.toDouble() ?? 0.0;
        }
        if (b is Movie || b is TvSeries) {
          popB = (b.popularity as num?)?.toDouble() ?? 0.0;
        }

        return popB.compareTo(popA);
      });

      if (mounted) {
        setState(() {
          _results = combinedResults;
          _isLoading = false;
        });
      }
    }

    void handleDone() {
      if (!mounted) return;
      if (!hasMovieEmission && !hasTvEmission) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }

    // Ci iscriviamo allo Stream dei film
    _movieSearchSubscription = sl<SearchMoviesUseCase>()
        .call(queryStr)
        .listen(
          (movies) {
            hasMovieEmission = true;
            latestMovies = movies;
            publishCombinedResults();
          },
          onError: (_) => handleDone(),
          onDone: handleDone,
        );

    // Ci iscriviamo allo Stream delle Serie TV simultaneamente
    _tvSearchSubscription = sl<SearchTvSeriesUseCase>()
        .call(queryStr)
        .listen(
          (series) {
            hasTvEmission = true;
            latestTv = series;
            publishCombinedResults();
          },
          onError: (_) => handleDone(),
          onDone: handleDone,
        );
  }

  void _listenToActorSearch(String queryStr) {
    var hasEmission = false;

    // Ci iscriviamo allo Stream degli Attori
    _actorSearchSubscription = sl<SearchActorsUseCase>()
        .call(queryStr)
        .listen(
          (actors) {
            hasEmission = true;
            if (!mounted) return;
            setState(() {
              _results = actors;
              _isLoading = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onDone: () {
            if (!mounted || hasEmission) return;
            setState(() {
              _results = [];
              _isLoading = false;
            });
          },
        );
  }

  @override
  void dispose() {
    _languageService.removeListener(_handleLanguageChanged);
    _debounce?.cancel();
    _movieSearchSubscription?.cancel();
    _tvSearchSubscription?.cancel();
    _actorSearchSubscription?.cancel();
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
          Expanded(child: _buildTabButton(0, AppLocalizations.of(context)!.moviesAndTv)),
          Expanded(child: _buildTabButton(1, AppLocalizations.of(context)!.actors)),
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
              _searchType == 0 ? AppLocalizations.of(context)!.searchMoviesTv : AppLocalizations.of(context)!.searchActors,
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
          AppLocalizations.of(context)!.noResultsFound,
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
