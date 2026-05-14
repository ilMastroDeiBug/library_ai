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
import '../domain/use_cases/movie_use_cases.dart';
import '../domain/use_cases/tv_series_use_cases.dart';
import '../domain/use_cases/actor_use_cases.dart';
import 'book_detail_page.dart';
import 'movie_detail_page.dart';
import 'actor_detail_page.dart';
import 'package:library_ai/l10n/app_localizations.dart';

// ─── ACCENT & PALETTE ────────────────────────────────────────────────────────
const _kAccent = Color(0xFFFF9500); // amber-orange, <80% sat
const _kBg = Color(0xFF0C0C0E);
const _kSurface = Color(0xFF151518);
const _kBorder = Color(0xFF242428);
const _kText = Color(0xFFEFEFF0);
const _kMuted = Color(0xFF6B6B72);

// ─── SEARCH DELEGATE ─────────────────────────────────────────────────────────
class UniversalSearchDelegate extends SearchDelegate {
  final AppMode mode;
  UniversalSearchDelegate({required this.mode});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: _kBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: IconThemeData(color: _kText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: _kMuted,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: _kText,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _kAccent,
        selectionColor: Color(0x55FF9500),
        selectionHandleColor: _kAccent,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        _FadeIn(
          child: GestureDetector(
            onTap: () {
              query = '';
              showSuggestions(context);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: _kMuted),
            ),
          ),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return GestureDetector(
      onTap: () => close(context, null),
      child: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _kText),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  @override
  Widget buildResults(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    if (mode == AppMode.books) {
      return _SearchEmptyState(
        icon: Icons.auto_stories_rounded,
        headline: 'Vault dei Libri',
        sub: AppLocalizations.of(context)!.searchBooksDisabled,
      );
    }
    return _DebouncedSearchList(
      query: query,
      mode: mode,
      closeDelegate: (r) => close(context, r),
    );
  }
}

// ─── DEBOUNCED SEARCH LIST ────────────────────────────────────────────────────
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

class _DebouncedSearchListState extends State<_DebouncedSearchList>
    with TickerProviderStateMixin {
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _lastSearchedQuery = '';
  int _searchType = 0;

  StreamSubscription<List<Movie>>? _movieSub;
  StreamSubscription<List<TvSeries>>? _tvSub;
  StreamSubscription<List<CastMember>>? _actorSub;

  final LanguageService _languageService = sl<LanguageService>();

  late final AnimationController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _languageService.addListener(_handleLanguageChanged);
    _queueSearch();
  }

  @override
  void didUpdateWidget(covariant _DebouncedSearchList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _queueSearch();
  }

  @override
  void dispose() {
    _languageService.removeListener(_handleLanguageChanged);
    _tabController.dispose();
    _debounce?.cancel();
    _movieSub?.cancel();
    _tvSub?.cancel();
    _actorSub?.cancel();
    super.dispose();
  }

  void _handleLanguageChanged() {
    _lastSearchedQuery = '';
    _queueSearch();
  }

  void _queueSearch() {
    final q = widget.query.trim();
    if (q.length < 3) {
      if (mounted)
        setState(() {
          _results = [];
          _isLoading = false;
          _lastSearchedQuery = '';
        });
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _movieSub?.cancel();
    _tvSub?.cancel();
    _actorSub?.cancel();
    setState(() => _isLoading = true);
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _performSearch(q),
    );
  }

  void _performSearch(String q) {
    final key = '$q::${_languageService.currentLanguage}::$_searchType';
    if (key == _lastSearchedQuery) {
      setState(() => _isLoading = false);
      return;
    }
    _lastSearchedQuery = key;
    if (_searchType == 0) {
      _listenMedia(q);
    } else {
      _listenActors(q);
    }
  }

  void _listenMedia(String q) {
    List<Movie> movies = [];
    List<TvSeries> tv = [];
    bool hasMov = false, hasTv = false;

    void publish() {
      final combined = <dynamic>[...movies, ...tv];
      combined.sort((a, b) {
        final pA = (a is Movie || a is TvSeries)
            ? ((a.popularity as num?)?.toDouble() ?? 0.0)
            : 0.0;
        final pB = (b is Movie || b is TvSeries)
            ? ((b.popularity as num?)?.toDouble() ?? 0.0)
            : 0.0;
        return pB.compareTo(pA);
      });
      if (mounted)
        setState(() {
          _results = combined;
          _isLoading = false;
        });
    }

    void done() {
      if (!mounted) return;
      if (!hasMov && !hasTv)
        setState(() {
          _results = [];
          _isLoading = false;
        });
    }

    _movieSub = sl<SearchMoviesUseCase>()
        .call(q)
        .listen(
          (m) {
            hasMov = true;
            movies = m;
            publish();
          },
          onError: (_) => done(),
          onDone: done,
        );
    _tvSub = sl<SearchTvSeriesUseCase>()
        .call(q)
        .listen(
          (s) {
            hasTv = true;
            tv = s;
            publish();
          },
          onError: (_) => done(),
          onDone: done,
        );
  }

  void _listenActors(String q) {
    bool hasEmit = false;
    _actorSub = sl<SearchActorsUseCase>()
        .call(q)
        .listen(
          (actors) {
            hasEmit = true;
            if (!mounted) return;
            setState(() {
              _results = actors;
              _isLoading = false;
            });
          },
          onError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onDone: () {
            if (!mounted || hasEmit) return;
            setState(() {
              _results = [];
              _isLoading = false;
            });
          },
        );
  }

  void _switchTab(int index) {
    if (_searchType == index) return;
    setState(() {
      _searchType = index;
      _lastSearchedQuery = '';
    });
    _queueSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Column(
        children: [
          _SearchTabBar(selectedIndex: _searchType, onSelect: _switchTab),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final q = widget.query.trim();

    if (q.length < 3) {
      return _SearchEmptyState(
        icon: _searchType == 0
            ? Icons.movie_filter_rounded
            : Icons.person_search_rounded,
        headline: _searchType == 0
            ? AppLocalizations.of(context)!.searchMoviesTv
            : AppLocalizations.of(context)!.searchActors,
        sub: 'Digita almeno 3 caratteri per iniziare',
      );
    }

    if (_isLoading) return const _SkeletonList();

    if (_results.isEmpty) {
      return _SearchEmptyState(
        icon: Icons.search_off_rounded,
        headline: AppLocalizations.of(context)!.noResultsFound,
        sub: 'Prova con un titolo diverso o controlla l\'ortografia',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _StaggeredItem(
          index: index,
          child: _SearchResultTile(item: _results[index], mode: widget.mode),
        );
      },
    );
  }
}

// ─── TAB BAR ─────────────────────────────────────────────────────────────────
class _SearchTabBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;

  const _SearchTabBar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      height: 40,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _TabChip(
            label: l10n.moviesAndTv,
            isSelected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _TabChip(
            label: l10n.actors,
            isSelected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : _kMuted,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── RESULT TILE ─────────────────────────────────────────────────────────────
class _SearchResultTile extends StatefulWidget {
  final dynamic item;
  final AppMode mode;

  const _SearchResultTile({required this.item, required this.mode});

  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    String title = '', subtitle = '', imageUrl = '';
    IconData defaultIcon = Icons.movie_rounded;
    VoidCallback onTap = () {};
    bool isActor = false;
    String? year;
    String typeLabel = '';

    if (item is Book) {
      title = item.title;
      subtitle = item.author;
      imageUrl = item.thumbnailUrl;
      defaultIcon = Icons.auto_stories_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailPage(book: item)),
      );
    } else if (item is Movie) {
      title = item.title;
      year = item.releaseDate.isNotEmpty
          ? item.releaseDate.split('-')[0]
          : null;
      typeLabel = AppLocalizations.of(context)!.movies;
      subtitle = year != null ? '$typeLabel · $year' : typeLabel;
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.movie_creation_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is TvSeries) {
      title = item.name;
      year = item.firstAirDate.isNotEmpty
          ? item.firstAirDate.split('-')[0]
          : null;
      typeLabel = AppLocalizations.of(context)!.tvSeries;
      subtitle = year != null ? '$typeLabel · $year' : typeLabel;
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.live_tv_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is CastMember) {
      title = item.name;
      subtitle = item.character.isNotEmpty ? item.character : 'Attore';
      imageUrl = item.fullProfileUrl;
      defaultIcon = Icons.person_rounded;
      isActor = true;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActorDetailPage(actorId: item.id)),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _pressed ? _kSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _pressed ? _kBorder : Colors.transparent),
          ),
          child: Row(
            children: [
              // ── Poster / Avatar
              _PosterThumbnail(
                imageUrl: imageUrl,
                icon: defaultIcon,
                isActor: isActor,
              ),
              const SizedBox(width: 14),

              // ── Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // ── Trailing chevron
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: _kBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── POSTER THUMBNAIL ─────────────────────────────────────────────────────────
class _PosterThumbnail extends StatelessWidget {
  final String imageUrl;
  final IconData icon;
  final bool isActor;

  const _PosterThumbnail({
    required this.imageUrl,
    required this.icon,
    required this.isActor,
  });

  @override
  Widget build(BuildContext context) {
    final double w = isActor ? 52 : 50;
    final double h = isActor ? 52 : 74;
    final radius = isActor
        ? BorderRadius.circular(26)
        : BorderRadius.circular(8);

    Widget placeholder = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: radius,
        border: Border.all(color: _kBorder),
      ),
      child: Icon(icon, color: _kMuted, size: 20),
    );

    if (imageUrl.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: w,
        height: h,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            _ShimmerBox(width: w, height: h, radius: radius),
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}

// ─── SKELETON LOADER ──────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            _ShimmerBox(
              width: 50,
              height: 74,
              radius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(
                    width: double.infinity,
                    height: 14,
                    radius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  _ShimmerBox(
                    width: 100,
                    height: 11,
                    radius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.radius,
          color: Color.lerp(
            const Color(0xFF1A1A1E),
            const Color(0xFF2C2C32),
            _anim.value,
          ),
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────
class _SearchEmptyState extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String sub;

  const _SearchEmptyState({
    required this.icon,
    required this.headline,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBorder),
                ),
                child: Icon(icon, size: 32, color: _kMuted),
              ),
              const SizedBox(height: 20),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 13,
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── STAGGERED REVEAL ────────────────────────────────────────────────────────
class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 30 * widget.index.clamp(0, 12)), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── FADE IN ─────────────────────────────────────────────────────────────────
class _FadeIn extends StatefulWidget {
  final Widget child;
  const _FadeIn({required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _ctrl, child: widget.child);
  }
}
