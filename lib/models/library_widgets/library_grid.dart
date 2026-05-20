import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/models/app_mode.dart';

// Entities
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/entities/favorite_item.dart';
import 'package:library_ai/domain/entities/tv_series_progress.dart';

// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_progress_use_cases.dart';
import 'package:library_ai/services/utility_services/watchlist_realtime_notifier.dart';

// Pages & Widgets
import 'package:library_ai/Pages/book_detail_page.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';
import 'package:library_ai/Pages/actor_detail_page.dart';
import 'package:library_ai/models/movie_widget/streak_widget.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';

class LibraryGrid extends StatefulWidget {
  final AppMode mode;
  final String status;

  const LibraryGrid({super.key, required this.mode, required this.status});

  @override
  State<LibraryGrid> createState() => _LibraryGridState();
}

class _LibraryGridState extends State<LibraryGrid> {
  String _searchQuery = "";
  String _selectedFilter = "Tutti";

  late Stream<List<dynamic>> _dataStream;

  bool _isSelectionMode = false;
  final Set<dynamic> _selectedItems = {};
  bool _isBulkActionLoading = false;

  List<String> get _availableFilters {
    final l10n = AppLocalizations.of(context);
    if (widget.mode == AppMode.books) return [l10n?.libFilterAll ?? 'Tutti'];
    if (widget.status == 'favorites') {
      return [l10n?.libFilterAll ?? 'Tutti', l10n?.libFilterMovies ?? 'Film', l10n?.libFilterTvSeries ?? 'Serie TV', l10n?.libFilterActors ?? 'Attori'];
    }
    return [l10n?.libFilterAll ?? 'Tutti', l10n?.libFilterMovies ?? 'Film', l10n?.libFilterTvSeries ?? 'Serie TV'];
  }

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant LibraryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode || oldWidget.status != widget.status) {
      _initStream();
      _isSelectionMode = false;
      _selectedItems.clear();
    }
  }

  void _initStream() {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      _dataStream = const Stream.empty();
      return;
    }

    if (widget.status == 'favorites') {
      final filterType = widget.mode == AppMode.books ? 'book' : null;
      _dataStream = sl<GetFavoritesStreamUseCase>().call(
        user.id,
        type: filterType,
      );
    } else if (widget.mode == AppMode.books) {
      _dataStream = sl<GetUserBooksUseCase>().call(user.id, widget.status);
    } else {
      _dataStream = sl<GetWatchlistUseCase>().call(user.id, widget.status);
    }
  }

  void _performBulkAction(String action) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;

    // Guard offline: blocca azioni bulk senza connessione
    if (!OfflineActionGuard.checkAndShow(context)) return;

    setState(() => _isBulkActionLoading = true);

    final optimisticIds = <int>{};
    final optimisticStatuses = <int, String>{};
    for (var item in _selectedItems) {
      final dynamic itemId = _extractId(item);
      if (itemId is int) {
        optimisticIds.add(itemId);
        optimisticStatuses[itemId] = action == 'delete' ? 'none' : action;
      }
    }
    setOptimisticMediaStatuses(optimisticStatuses);

    try {
      for (var item in _selectedItems) {
        final dynamic itemId = _extractId(item);
        final String itemType = _extractType(item);

        if (action == 'delete') {
          if (widget.status == 'favorites') {
            await sl<ToggleFavoriteUseCase>().call(
              user.id,
              itemId as int,
              itemType,
              _extractTitle(item),
              null,
            );
          } else {
            if (itemType == 'tv') {
              await sl<DeleteTvSeriesUseCase>().call(user.id, itemId as int);
              try {
                await sl<DeleteSeriesProgressUseCase>().call(
                  user.id,
                  itemId as int,
                );
              } catch (_) {}
            } else if (itemType == 'book') {
              await sl<DeleteBookUseCase>().call(user.id, itemId as String);
            } else {
              await sl<DeleteMovieUseCase>().call(user.id, itemId as int);
            }
          }
        } else {
          if (item is Movie) {
            final updated = item.copyWith(status: action);
            await sl<SaveMovieUseCase>().call(updated, user.id);
          } else if (item is TvSeries) {
            final updated = item.copyWith(status: action);
            await sl<SaveTvSeriesUseCase>().call(updated, user.id);
            if (action != 'watching') {
              try {
                await sl<DeleteSeriesProgressUseCase>().call(user.id, item.id);
              } catch (_) {}
            }
          } else if (item is Book) {
            final updated = Book(
              id: item.id,
              title: item.title,
              author: item.author,
              description: item.description,
              thumbnailUrl: item.thumbnailUrl,
              pageCount: item.pageCount,
              rating: item.rating,
              ratingsCount: item.ratingsCount,
              status: action,
              aiAnalysis: item.aiAnalysis,
            );
            await sl<AddBookUseCase>().call(updated, user.id);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Errore durante l'operazione.")),
        );
      }
    } finally {
      clearOptimisticMediaStatuses(optimisticIds);
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedItems.clear();
          _isBulkActionLoading = false;
        });
      }
    }
  }

  dynamic _extractId(dynamic item) {
    if (item is FavoriteItem) return item.itemId;
    return item.id;
  }

  String _extractType(dynamic item) {
    if (item is FavoriteItem) return item.itemType;
    if (item is TvSeries) return 'tv';
    if (item is Book) return 'book';
    return 'movie';
  }

  String _extractTitle(dynamic item) {
    if (item is FavoriteItem) return item.title;
    if (item is TvSeries) return item.name;
    if (item is Movie) return item.title;
    if (item is Book) return item.title;
    return '';
  }

  void _toggleSelection(dynamic item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int, String>>(
      valueListenable: globalOptimisticStatus,
      builder: (context, optimisticMap, child) {
        return Stack(
          children: [
            Column(
              children: [
                _buildSearchAndFilterHeader(),
                Expanded(
                  child: StreamBuilder<List<dynamic>>(
                    stream: _dataStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                        );
                      }

                      final allItems = snapshot.data ?? [];
                      // PASSIAMO LA MAPPA AL FILTRO
                      final filteredItems = _applyLocalFilters(
                        allItems,
                        optimisticMap,
                      );

                      if (filteredItems.isEmpty) return _buildEmptyState();

                      return GridView.builder(
                        padding: const EdgeInsets.only(
                          top: 10,
                          left: 15,
                          right: 15,
                          bottom: 150,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (context, index) {
                          return _buildItemCard(context, filteredItems[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isBulkActionLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              ),
            if (_isSelectionMode &&
                _selectedItems.isNotEmpty &&
                !_isBulkActionLoading)
              Positioned(
                bottom: 130,
                left: 20,
                right: 20,
                child: _buildBulkActionBar(),
              ),
          ],
        );
      },
    );
  }

  List<dynamic> _applyLocalFilters(
    List<dynamic> items,
    Map<int, String> optimisticMap,
  ) {
    final seenIds = <dynamic>{};

    return items.where((item) {
      final id = _extractId(item);

      // Scudo Anti-Doppioni del DB
      if (seenIds.contains(id)) return false;
      seenIds.add(id);

      // SCUDO OPTIMISTIC UI CORRETTO
      if (widget.status != 'favorites' &&
          id is int &&
          optimisticMap.containsKey(id)) {
        final optStatus = optimisticMap[id];
        // Se lo stato ottimistico dice che è stato rimosso o si trova in un'altra tab, NASCONDILO.
        if (optStatus == 'none' || optStatus != widget.status) {
          return false;
        }
      }

      String title = _extractTitle(item);
      if (_searchQuery.isNotEmpty &&
          !title.toLowerCase().contains(_searchQuery))
        return false;

      final l10n = AppLocalizations.of(context);
      if (_selectedFilter != (l10n?.libFilterAll ?? 'Tutti')) {
        final type = _extractType(item);
        if (_selectedFilter == (l10n?.libFilterMovies ?? 'Film') && type != 'movie') return false;
        if (_selectedFilter == (l10n?.libFilterTvSeries ?? 'Serie TV') && type != 'tv') return false;
        if (_selectedFilter == (l10n?.libFilterActors ?? 'Attori') && type != 'person') return false;
      }
      return true;
    }).toList();
  }

  Widget _buildSearchAndFilterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.libSearchHint,
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) _selectedItems.clear();
                  });
                },
                child: Text(
                  _isSelectionMode ? AppLocalizations.of(context)!.libCancel : AppLocalizations.of(context)!.libSelect,
                  style: TextStyle(
                    color: _isSelectionMode
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_availableFilters.length > 1)
            SizedBox(
              height: 35,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _availableFilters.length,
                itemBuilder: (context, index) {
                  final filter = _availableFilters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.orangeAccent,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      side: BorderSide.none,
                      showCheckmark: false,
                      onSelected: (selected) =>
                          setState(() => _selectedFilter = filter),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, dynamic item) {
    final user = sl<AuthRepository>().currentUser;
    String imageUrl = "";
    String overlayName = "";

    if (item is Book) {
      imageUrl = item.thumbnailUrl;
      overlayName = item.title;
    } else if (item is Movie) {
      imageUrl = item.fullPosterUrl;
      overlayName = item.title;
    } else if (item is TvSeries) {
      imageUrl = item.fullPosterUrl;
      overlayName = item.name;
    } else if (item is FavoriteItem) {
      imageUrl = item.posterUrl ?? '';
      overlayName = item.title;
    }

    final isSelected = _selectedItems.contains(item);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item);
          return;
        }

        if (item is FavoriteItem) {
          if (item.itemType == 'person') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActorDetailPage(actorId: item.itemId),
              ),
            );
            return;
          }
          final String barePath =
              (item.posterUrl != null && item.posterUrl!.startsWith('http'))
              ? item.posterUrl!.replaceAll(
                  RegExp(r'https://image\.tmdb\.org/t/p/w\d+'),
                  '',
                )
              : (item.posterUrl ?? '');

          dynamic stubMedia = (item.itemType == 'movie')
              ? Movie(
                  id: item.itemId,
                  title: item.title,
                  overview: '',
                  posterPath: barePath,
                  backdropPath: barePath,
                  voteAverage: 0.0,
                  voteCount: 0,
                  releaseDate: '',
                  popularity: 0.0,
                  status: 'none',
                )
              : TvSeries(
                  id: item.itemId,
                  name: item.title,
                  overview: '',
                  posterPath: barePath,
                  backdropPath: barePath,
                  voteAverage: 0.0,
                  voteCount: 0,
                  firstAirDate: '',
                  popularity: 0.0,
                  status: 'none',
                );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailPage(media: stubMedia),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => (item is Book)
                ? BookDetailPage(book: item)
                : MovieDetailPage(media: item),
          ),
        );
      },
      onLongPress: () {
        if (!_isSelectionMode)
          setState(() {
            _isSelectionMode = true;
            _selectedItems.add(item);
          });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Colors.orangeAccent
                    : Colors.white.withOpacity(0.05),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(
                          widget.mode == AppMode.books
                              ? Icons.book
                              : Icons.movie,
                          color: Colors.white24,
                          size: 30,
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Icon(
                      widget.mode == AppMode.books ? Icons.book : Icons.movie,
                      color: Colors.white24,
                      size: 30,
                    ),
                  ),
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
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
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
                      overlayName.toUpperCase(),
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
              ],
            ),
          ),
          if (item is TvSeries && user != null)
            Positioned(
              top: 6,
              left: 6,
              child: _TvSeriesProgressIndicator(
                userId: user.id,
                seriesId: item.id,
              ),
            ),
          if (_isSelectionMode)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.orangeAccent : Colors.black45,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: isSelected ? Colors.black : Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _getBulkActionButtons(),
          ),
        ),
      ),
    );
  }

  List<Widget> _getBulkActionButtons() {
    List<Widget> buttons = [];
    buttons.add(
      _buildBulkBtn(
        Icons.delete_outline,
        AppLocalizations.of(context)!.libBulkDelete,
        Colors.redAccent,
        () => _performBulkAction('delete'),
      ),
    );

    if (widget.status == 'towatch' || widget.status == 'toread') {
      buttons.add(
        _buildBulkBtn(
          Icons.play_circle_outline,
          AppLocalizations.of(context)!.libBulkWatching,
          Colors.orangeAccent,
          () => _performBulkAction(
            widget.mode == AppMode.books ? 'reading' : 'watching',
          ),
        ),
      );
      buttons.add(
        _buildBulkBtn(
          Icons.check_circle_outline,
          widget.mode == AppMode.books ? AppLocalizations.of(context)!.libBulkRead : AppLocalizations.of(context)!.libBulkWatched,
          Colors.greenAccent,
          () => _performBulkAction(
            widget.mode == AppMode.books ? 'read' : 'watched',
          ),
        ),
      );
    } else if (widget.status == 'watching' || widget.status == 'reading') {
      buttons.add(
        _buildBulkBtn(
          Icons.check_circle_outline,
          widget.mode == AppMode.books ? AppLocalizations.of(context)!.libBulkRead : AppLocalizations.of(context)!.libBulkWatched,
          Colors.greenAccent,
          () => _performBulkAction(
            widget.mode == AppMode.books ? 'read' : 'watched',
          ),
        ),
      );
    }
    return buttons;
  }

  Widget _buildBulkBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.mode == AppMode.books
                ? Icons.auto_stories
                : Icons.movie_filter_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? AppLocalizations.of(context)!.libEmptyNoResults
                : (widget.status == 'favorites'
                      ? AppLocalizations.of(context)!.libEmptyNoFavorites
                      : AppLocalizations.of(context)!.libEmptyNoItems),
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              letterSpacing: 2.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TvSeriesProgressIndicator extends StatefulWidget {
  final String userId;
  final int seriesId;

  const _TvSeriesProgressIndicator({
    super.key,
    required this.userId,
    required this.seriesId,
  });

  @override
  State<_TvSeriesProgressIndicator> createState() =>
      _TvSeriesProgressIndicatorState();
}

class _TvSeriesProgressIndicatorState
    extends State<_TvSeriesProgressIndicator> {
  late Stream<TvSeriesProgress?> _progressStream;

  @override
  void initState() {
    super.initState();
    _progressStream = sl<GetSeriesProgressUseCase>().call(
      widget.userId,
      widget.seriesId,
    );
  }

  @override
  void didUpdateWidget(covariant _TvSeriesProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.seriesId != widget.seriesId) {
      _progressStream = sl<GetSeriesProgressUseCase>().call(
        widget.userId,
        widget.seriesId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TvSeriesProgress?>(
      stream: _progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        return StreakWidget(progress: snapshot.data!);
      },
    );
  }
}
