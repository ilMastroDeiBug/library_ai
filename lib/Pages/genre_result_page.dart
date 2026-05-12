import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../domain/entities/category.dart';
import '../models/app_mode.dart';
import '../injection_container.dart';
import '../domain/use_cases/movie_use_cases.dart';
import '../domain/use_cases/tv_series_use_cases.dart';
import '../domain/use_cases/book_use_cases.dart';
import '../domain/entities/book.dart';
import '../domain/entities/movie.dart';
import '../domain/entities/tv_series.dart';
import 'movie_detail_page.dart';
import 'book_detail_page.dart';
import '../services/utility_services/language_service.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class GenreResultPage extends StatefulWidget {
  final CategoryEntity category;
  final AppMode mode;
  final bool isTvSeries;

  const GenreResultPage({
    super.key,
    required this.category,
    required this.mode,
    this.isTvSeries = false,
  });

  @override
  State<GenreResultPage> createState() => _GenreResultPageState();
}

class _GenreResultPageState extends State<GenreResultPage> {
  final ScrollController _scrollController = ScrollController();
  final LanguageService _languageService = sl<LanguageService>();

  List<dynamic> _items = [];
  int _currentPage = 1;
  bool _isLoadingFirstTime = true;
  bool _isFetchingMore = false;
  bool _hasReachedMax = false;
  StreamSubscription<List<dynamic>>? _initialItemsSubscription;
  StreamSubscription<List<dynamic>>? _moreItemsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
    _languageService.addListener(_handleLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_handleLanguageChanged);
    _initialItemsSubscription?.cancel();
    _moreItemsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _items = [];
      _currentPage = 1;
      _isLoadingFirstTime = true;
      _isFetchingMore = false;
      _hasReachedMax = false;
    });
    _fetchInitialData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && !_hasReachedMax && !_isLoadingFirstTime) {
        _fetchMoreData();
      }
    }
  }

  void _fetchInitialData() {
    _initialItemsSubscription?.cancel();
    var hasEmitted = false;
    List<dynamic> lastEmission = const [];

    _initialItemsSubscription = _itemsStream(1).listen(
      (newItems) {
        hasEmitted = true;
        lastEmission = newItems;
        if (!mounted) return;
        setState(() {
          _items = newItems;
          _isLoadingFirstTime = false;
          _hasReachedMax = widget.mode == AppMode.books;
        });
      },
      onDone: () {
        if (!mounted) return;

        setState(() {
          _isLoadingFirstTime = false;
          _hasReachedMax =
              widget.mode == AppMode.books || !hasEmitted || lastEmission.isEmpty;
        });

        _fetchNextPageIfStillNearBottom();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoadingFirstTime = false;
          _hasReachedMax = false;
        });
      },
    );
  }

  void _fetchMoreData() {
    setState(() {
      _isFetchingMore = true;
    });

    final nextPage = _currentPage + 1;
    _moreItemsSubscription?.cancel();
    var hasEmitted = false;
    List<dynamic> lastEmission = const [];

    _moreItemsSubscription = _itemsStream(nextPage).listen(
      (newItems) {
        hasEmitted = true;
        lastEmission = newItems;
        if (!mounted || newItems.isEmpty) return;

        // Filtro Anti-Cloni
        final existingIds = _items.map((e) => _getId(e)).toSet();
        final actuallyNew = newItems
            .where((e) => !existingIds.contains(_getId(e)))
            .toList();

        if (actuallyNew.isEmpty) return;

        setState(() {
          _items.addAll(actuallyNew);
          _hasReachedMax = false;
        });
      },
      onDone: () {
        if (!mounted) return;

        setState(() {
          _isFetchingMore = false;
          if (hasEmitted && lastEmission.isNotEmpty) {
            _currentPage = nextPage;
            _hasReachedMax = false;
          } else {
            _hasReachedMax = true;
          }
        });

        _fetchNextPageIfStillNearBottom();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isFetchingMore = false;
          _hasReachedMax = false;
        });
      },
    );
  }

  void _fetchNextPageIfStillNearBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isLoadingFirstTime ||
          _isFetchingMore ||
          _hasReachedMax ||
          widget.mode == AppMode.books ||
          !_scrollController.hasClients) {
        return;
      }

      final position = _scrollController.position;
      final isNearBottom =
          position.maxScrollExtent <= 0 ||
          position.pixels >= position.maxScrollExtent - 200;

      if (isNearBottom) {
        _fetchMoreData();
      }
    });
  }

  // Helper per estrarre l'ID in modo sicuro
  dynamic _getId(dynamic item) {
    if (item is Book) return item.id;
    if (item is Movie) return item.id;
    if (item is TvSeries) return item.id;
    return item.hashCode;
  }

  Stream<List<dynamic>> _itemsStream(int page) async* {
    try {
      if (widget.mode == AppMode.books) {
        if (page > 1) {
          yield [];
          return;
        }
        // Il libro è un Future, lo yieldiamo
        final books = await sl<GetBooksByCategoryUseCase>().call(
          widget.category.name,
        );
        yield List<dynamic>.from(books);
      } else {
        final path = 'with_genres=${widget.category.id}';
        if (widget.isTvSeries) {
          // Usiamo map per castare correttamente la lista a dynamic
          yield* sl<GetTvSeriesByCategoryUseCase>()
              .call(path, page: page)
              .map((list) => List<dynamic>.from(list));
        } else {
          yield* sl<GetMoviesByCategoryUseCase>()
              .call(path, page: page)
              .map((list) => List<dynamic>.from(list));
        }
      }
    } catch (e) {
      yield [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            floating: true,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.category.name.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          if (_isLoadingFirstTime)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              ),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
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
                      AppLocalizations.of(context)!.genreNoResults,
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 15,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _GridItemCard(item: _items[index]);
                }, childCount: _items.length),
              ),
            ),
          if (_isFetchingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 20, bottom: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _GridItemCard extends StatelessWidget {
  final dynamic item;
  const _GridItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String imageUrl = '';
    String title = '';
    double rating = 0.0;

    if (item is Book) {
      imageUrl = item.thumbnailUrl;
      title = item.title;
      rating = (item.rating as num).toDouble();
    } else if (item is Movie) {
      imageUrl = item.fullPosterUrl;
      title = item.title;
      rating = (item.voteAverage as num).toDouble();
    } else if (item is TvSeries) {
      imageUrl = item.fullPosterUrl;
      title = item.name;
      rating = (item.voteAverage as num).toDouble();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => item is Book
                ? BookDetailPage(book: item)
                : MovieDetailPage(media: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF161618),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orangeAccent,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 25,
                    bottom: 8,
                    left: 6,
                    right: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (rating > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.orangeAccent,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.white24,
          size: 30,
        ),
      ),
    );
  }
}
