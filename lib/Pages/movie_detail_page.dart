import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart';
import 'package:library_ai/domain/use_cases/ai_use_cases.dart';

import '../services/pages_services/movie_detail_logic.dart';
import '../models/ai_analysis_section.dart';
import '../models/movie_widget/movie_reviews_section.dart';
import '../models/movie_widget/movie_cast_section.dart';
import '../models/movie_widget/movie_crew_section.dart';
import '../models/movie_widget/trailer_player_widget.dart';
import '../models/movie_widget/watch_provider_widgets.dart';
import 'package:library_ai/models/movie_widget/tv_series_tracker_section.dart';
import '../models/movie_widget/emoji_rating_widget.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';
import 'package:library_ai/Pages/collections/add_to_collection_bottom_sheet.dart';

class MovieDetailPage extends StatefulWidget {
  final dynamic media;
  const MovieDetailPage({super.key, required this.media});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final MovieDetailLogic _logic = MovieDetailLogic();
  bool _isAnalyzing = false;

  // UI OTTIMISTICA
  StreamSubscription<bool>? _favSubscription;
  bool _isFavorite = false;
  bool _isTogglingHeart = false;

  String? _optimisticStatus;
  bool _isTogglingStatus = false;

  Future<dynamic>? _mediaFuture;

  static const Color _brandColor = Colors.white;
  static const Color _backgroundColor = Color(0xFF0A0A0A);

  bool get _isTv => widget.media is TvSeries;
  int get _id => widget.media.id;

  @override
  void initState() {
    super.initState();
    _initFavoriteStream();
    final user = sl<AuthRepository>().currentUser;
    if (user != null) {
      _mediaFuture = _getMediaFuture(user.id);
    }
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    super.dispose();
  }

  void _initFavoriteStream() {
    final user = sl<AuthRepository>().currentUser;
    if (user != null) {
      _favSubscription = sl<CheckFavoriteStatusUseCase>()
          .call(user.id, _id, _isTv ? 'tv' : 'movie')
          .listen((isFav) {
        if (!_isTogglingHeart && mounted) {
          setState(() => _isFavorite = isFav);
        }
      });
    }
  }

  void _showRatingBottomSheet(BuildContext context, dynamic media) {
    if (!OfflineActionGuard.checkAndShow(context)) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return EmojiRatingWidget(media: media);
      },
    );
  }

  void _handleFavoriteToggle(dynamic liveMedia) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;
    if (!OfflineActionGuard.checkAndShow(context)) return;

    setState(() {
      _isTogglingHeart = true;
      _isFavorite = !_isFavorite;
    });

    try {
      final result = await _logic.toggleFavorite(context, liveMedia);
      if (mounted) setState(() => _isFavorite = result);
    } catch (e) {
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } finally {
      if (mounted) setState(() => _isTogglingHeart = false);
    }
  }

  void _showCollectionsBottomSheet(String title) {
    if (!OfflineActionGuard.checkAndShow(context)) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return AddToCollectionBottomSheet(
          itemId: _id.toString(),
          itemType: _isTv ? 'tv' : 'movie',
          title: title,
        );
      },
    );
  }

  void _handleStatusToggle(
    dynamic liveMedia,
    String action,
    String streamStatus,
  ) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;
    if (!OfflineActionGuard.checkAndShow(context)) return;

    final isRemoving = streamStatus == action;
    final targetStatus = isRemoving ? 'none' : action;

    setState(() {
      _isTogglingStatus = true;
      _optimisticStatus = targetStatus;
    });

    try {
      final success = await _logic.handleStatusAction(
        context,
        liveMedia,
        action,
        streamStatus,
      );
      if (mounted && !success) {
        setState(() => _optimisticStatus = streamStatus);
      } else if (mounted && success && action == 'watched' && !isRemoving) {
        _showRatingBottomSheet(context, liveMedia);
      }
    } catch (e) {
      if (mounted) setState(() => _optimisticStatus = streamStatus);
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  // Nuova funzione per Memory Forge Ultra Premium
  Future<void> _showMemoryForgeDialog(String title) async {
    bool isLoading = false;
    String? resultText;
    String? errorMessage;
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09090B).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 30,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 24),
                        const Text(
                          "Memory Forge",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Forgiando ricordi per: $title",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (resultText == null && errorMessage == null && !isLoading) ...[
                           Text(
                            "Vuoi creare un ricordo dettagliato con l'AI per questa opera? Costerà 1 token.",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                        ] else if (isLoading) ...[
                          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          const SizedBox(height: 24),
                          const Text(
                            "Forgiatura in corso...",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          )
                        ] else if (errorMessage != null) ...[
                          const Icon(Icons.error_outline, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ] else if (resultText != null) ...[
                          Flexible(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Text(
                                resultText!,
                                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            if (!isLoading)
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    resultText != null ? "Chiudi" : "Annulla",
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            if (!isLoading && resultText == null && errorMessage == null) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      isLoading = true;
                                      errorMessage = null;
                                    });
                                    try {
                                      final useCase = sl<CallAiFunctionUseCase>();
                                      final response = await useCase.call(
                                        userId: user.id,
                                        functionName: 'memory_forge',
                                        payload: {'title': title},
                                        tokenCost: 1, 
                                      );
                                      setState(() {
                                        resultText = response;
                                        isLoading = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        errorMessage = "Errore durante la generazione: ${e.toString().replaceAll('Exception: ', '')}";
                                        isLoading = false;
                                      });
                                    }
                                  },
                                  child: const Text("Forgia Ora", style: TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<dynamic>? _getMediaFuture(String userId) async {
    try {
      if (_isTv) {
        return await sl<GetSingleTvSeriesUseCase>().call(userId, _id.toString()).first;
      }
      return await sl<GetSingleMovieUseCase>().call(userId, _id.toString()).first;
    } catch (e) {
      return null;
    }
  }

  Map<int, int> _extractSeasonsMap(dynamic liveMedia) {
    if (liveMedia is! TvSeries) return {};
    Map<int, int> map = {};
    if (liveMedia.seasons.isEmpty) return map;

    for (var s in liveMedia.seasons) {
      if (s is Map) {
        final sNum = s['season_number'] ?? 0;
        final epCount = s['episode_count'] ?? 0;
        if (sNum > 0) {
          map[sNum] = epCount;
        }
      }
    }
    return map;
  }

  // Helpers per formattazione data
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(dateStr);
      final List<String> months = [
        'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
        'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRepository>().currentUser;

    return FutureBuilder<dynamic>(
      future: _mediaFuture,
      builder: (context, snapshot) {
        dynamic liveMedia = widget.media;
        if (snapshot.hasData && snapshot.data != null) {
          liveMedia = snapshot.data;
        }

        final String streamStatus = liveMedia.status ?? 'none';
        final String currentStatus = _isTogglingStatus
            ? _optimisticStatus!
            : (_optimisticStatus ?? streamStatus);

        final String? storedAnalysis = liveMedia.aiAnalysis;
        final String title = _isTv ? liveMedia.name : liveMedia.title;
        final String overview = liveMedia.overview;
        final String poster = liveMedia.fullPosterUrl;
        final String backdrop = liveMedia.fullBackdropUrl;
        final String releaseDate = _isTv ? liveMedia.firstAirDate : liveMedia.releaseDate;
        final double voteAvg = liveMedia.voteAverage;
        final int voteCount = liveMedia.voteCount;
        final List<String> genres = liveMedia.genres;
        final String productionStatus = liveMedia.productionStatus;
        
        final List<String> createdBy = _isTv ? liveMedia.createdBy : [];
        final Map<int, int> seasonsMap = _extractSeasonsMap(liveMedia);
        final int? runtime = liveMedia.runtime;

        return Scaffold(
          backgroundColor: _backgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar((poster.isNotEmpty ? poster : backdrop).replaceAll('w500', 'original')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Titolo e Azioni Rapide
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (user != null)
                            Row(
                              children: [
                                _buildIconBtn(
                                  icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: _isFavorite ? Colors.white : Colors.white,
                                  onTap: () => _handleFavoriteToggle(liveMedia),
                                ),
                                const SizedBox(width: 12),
                                _buildIconBtn(
                                  icon: Icons.collections_bookmark_outlined,
                                  color: Colors.white,
                                  onTap: () => _showCollectionsBottomSheet(title),
                                ),
                                const SizedBox(width: 12),
                                _buildIconBtn(
                                  icon: Icons.share_rounded,
                                  color: Colors.white,
                                  onTap: () {}, // Implementare share se necessario
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Info Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (releaseDate.isNotEmpty)
                            _GlassChip(text: _formatDate(releaseDate)),
                          _GlassChip(
                            text: _isTv ? 'Serie TV' : 'Film',
                            baseColor: Colors.white,
                            isSolid: true,
                          ),
                          if (_isTv && seasonsMap.isNotEmpty)
                            _GlassChip(text: '${seasonsMap.length} Stagioni'),
                          if (!_isTv && runtime != null && runtime > 0)
                            _GlassChip(text: '$runtime min'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (productionStatus.isNotEmpty)
                        _GlassChip(text: 'Produzione: ${productionStatus.toUpperCase()}'),
                      const SizedBox(height: 24),

                      // Creato da
                      if (_isTv && createdBy.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              'CREATO DA: ',
                              style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                createdBy.join(', '),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Icon(Icons.people_outline, color: Colors.white54, size: 20),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Generi
                      if (genres.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: genres.map((g) => _GlassChip(text: g, dark: true)).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Ratings Container
                      if (voteAvg > 0) ...[
                        _buildRatingContainer(voteAvg, voteCount),
                        const SizedBox(height: 12),
                      ],


                      const SizedBox(height: 36),

                      // TV TRACKER
                      if (_isTv && currentStatus == 'watching' && user != null) ...[
                        Text(
                          AppLocalizations.of(context)!.viewProgress,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TvSeriesTrackerSection(
                          userId: user.id,
                          seriesId: _id,
                          episodesPerSeason: seasonsMap,
                        ),
                        const SizedBox(height: 36),
                      ],

                      // STATUS BUTTONS (Towatch, Watching, Watched)
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: AppLocalizations.of(context)!.toWatch.toUpperCase(),
                              icon: Icons.bookmark_add_outlined,
                              isActive: currentStatus == 'towatch',
                              onTap: () => _handleStatusToggle(liveMedia, 'towatch', streamStatus),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              label: AppLocalizations.of(context)!.watching.toUpperCase(),
                              icon: Icons.play_circle_outline_rounded,
                              isActive: currentStatus == 'watching',
                              onTap: () => _handleStatusToggle(liveMedia, 'watching', streamStatus),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              label: AppLocalizations.of(context)!.watchedAction.toUpperCase(),
                              icon: Icons.check_circle_outline,
                              isActive: currentStatus == 'watched',
                              onTap: () => _handleStatusToggle(liveMedia, 'watched', streamStatus),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // AI ANALYSIS
                      AIAnalysisSection(
                        analysisText: storedAnalysis,
                        isAnalyzing: _isAnalyzing,
                        onAnalyzeTap: () async {
                          setState(() => _isAnalyzing = true);
                          await _logic.handleAnalysis(context, liveMedia);
                          if (mounted) setState(() => _isAnalyzing = false);
                        },
                      ),
                      const SizedBox(height: 16),

                      // MEMORY FORGE BUTTON
                      GestureDetector(
                        onTap: () => _showMemoryForgeDialog(title),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.auto_stories_rounded, color: Colors.black, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Memory Forge",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Genera un ricordo ultra-dettagliato di quest'opera.",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // OVERVIEW
                      Text(
                        AppLocalizations.of(context)!.plot.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        overview.isNotEmpty ? overview : AppLocalizations.of(context)!.noPlotAvailable,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // WATCH PROVIDERS & TRAILER
                      WatchProvidersWidget(mediaId: _id, isTvSeries: _isTv),
                      TrailerPlayerWidget(mediaId: _id, isTvSeries: _isTv),
                      
                      // CAST & CREW
                      MovieCastSection(id: _id, isTvSeries: _isTv),
                      const SizedBox(height: 24),
                      MovieCrewSection(id: _id, isTvSeries: _isTv),
                      
                      // REVIEWS
                      MovieReviewsSection(id: _id, title: title, isTvSeries: _isTv),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(String imageUrl) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      stretch: true,
      backgroundColor: _backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background layer
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: (_, __) => const ColoredBox(color: Color(0xFF0C0C0C)),
              errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF0A0A0A)),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
            
            // Sharp, fully visible poster layer
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
            
            // Gradient cinematico profondo per sfumare dolcemente con il background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x000A0A0A),
                    Color(0x000A0A0A),
                    Color(0x880A0A0A),
                    Color(0xFF0A0A0A),
                  ],
                  stops: [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 26),
    );
  }

  Widget _buildRatingContainer(double voteAvg, int voteCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Text(
            voteAvg.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'TMDB', // Uso TMDB al posto di IMDB visto che la fonte è quella
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$voteCount voti',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          backgroundColor: isActive ? _brandColor : const Color(0xFF1A1A1A),
          foregroundColor: isActive ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isActive ? _brandColor : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Componente GlassChip ────────────────────────────────────────────────────
class _GlassChip extends StatelessWidget {
  final String text;
  final bool dark;
  final bool isSolid;
  final Color? baseColor;

  const _GlassChip({
    required this.text,
    this.dark = false,
    this.isSolid = false,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isSolid && baseColor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.7,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: dark ? Colors.white70 : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
