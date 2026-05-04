import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart';

import '../services/pages_services/movie_detail_logic.dart';
import '../models/ai_analysis_section.dart';
import '../models/movie_widget/movie_stats_bar.dart';
import '../models/movie_widget/movie_reviews_section.dart';
import '../models/movie_widget/movie_cast_section.dart';
import '../models/movie_widget/trailer_player_widget.dart';
import '../models/movie_widget/watch_provider_widgets.dart';

class MovieDetailPage extends StatefulWidget {
  final dynamic media;
  const MovieDetailPage({super.key, required this.media});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final MovieDetailLogic _logic = MovieDetailLogic();
  bool _isAnalyzing = false;

  // STATO OTTIMISTICO PER IL CUORE
  bool? _optimisticIsFavorite;

  static const Color _brandColor = Colors.orangeAccent;
  static const Color _backgroundColor = Colors.black;

  bool get _isTv => widget.media is TvSeries;
  int get _id => widget.media.id;

  Stream<dynamic>? _getMediaStream(String userId) {
    try {
      if (_isTv) {
        return sl<GetSingleTvSeriesUseCase>().call(userId, _id.toString());
      } else {
        return sl<GetSingleMovieUseCase>().call(userId, _id.toString());
      }
    } catch (e) {
      return null;
    }
  }

  void _handleFavoriteToggle(dynamic liveMedia) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;

    // 1. Leggiamo lo stato attuale
    final currentFavState = _optimisticIsFavorite ?? false;

    // 2. Invertiamo subito la UI (Optimistic UI)
    setState(() {
      _optimisticIsFavorite = !currentFavState;
    });

    // 3. Facciamo il vero salvataggio
    try {
      final actualResult = await _logic.toggleFavorite(context, liveMedia);
      if (mounted) {
        setState(() {
          _optimisticIsFavorite = actualResult; // Sincronizziamo con la realtà
        });
      }
    } catch (e) {
      // 4. Se fallisce, torniamo indietro
      if (mounted) {
        setState(() {
          _optimisticIsFavorite = currentFavState;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRepository>().currentUser;

    return StreamBuilder<dynamic>(
      stream: user != null ? _getMediaStream(user.id) : null,
      builder: (context, snapshot) {
        dynamic liveMedia = widget.media;
        if (snapshot.hasData && snapshot.data != null) {
          liveMedia = snapshot.data;
        }

        final String currentStatus = liveMedia.status ?? 'none';
        final String? storedAnalysis = liveMedia.aiAnalysis;
        final String title = _isTv ? liveMedia.name : liveMedia.title;
        final String overview = liveMedia.overview;
        final String poster = liveMedia.fullPosterUrl;
        final String backdrop = liveMedia.fullBackdropUrl;

        final displayMovieForStats = _isTv
            ? Movie(
                id: _id,
                title: title,
                overview: overview,
                posterPath: liveMedia.posterPath,
                backdropPath: liveMedia.backdropPath,
                voteAverage: liveMedia.voteAverage,
                voteCount: liveMedia.voteCount,
                releaseDate: liveMedia.firstAirDate,
                popularity: liveMedia.popularity,
                status: currentStatus,
              )
            : liveMedia as Movie;

        return Scaffold(
          backgroundColor: _backgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(backdrop, poster),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITOLO E CUORE PREFERITI
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (user != null)
                            StreamBuilder<bool>(
                              stream: sl<CheckFavoriteStatusUseCase>().call(
                                user.id,
                                _id,
                                _isTv ? 'tv' : 'movie',
                              ),
                              builder: (context, favSnapshot) {
                                // Se abbiamo un override ottimistico usiamo quello, altrimenti il db
                                final isFavorite =
                                    _optimisticIsFavorite ??
                                    (favSnapshot.data ?? false);

                                return GestureDetector(
                                  onTap: () => _handleFavoriteToggle(liveMedia),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isFavorite
                                          ? Colors.redAccent.withOpacity(0.1)
                                          : Colors.white.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        key: ValueKey(isFavorite),
                                        color: isFavorite
                                            ? Colors.redAccent
                                            : Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      MovieStatsBar(movie: displayMovieForStats),
                      const SizedBox(height: 30),

                      // I TRE BOTTONI
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: "DA VEDERE",
                              icon: Icons.bookmark_add_outlined,
                              isActive: currentStatus == 'towatch',
                              onTap: () => _logic.handleStatusAction(
                                context,
                                liveMedia,
                                'towatch',
                                currentStatus,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              label: "IN CORSO",
                              icon: Icons.play_circle_outline_rounded,
                              isActive: currentStatus == 'watching',
                              onTap: () => _logic.handleStatusAction(
                                context,
                                liveMedia,
                                'watching',
                                currentStatus,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              label: "VISTO",
                              icon: Icons.check_circle_outline,
                              isActive: currentStatus == 'watched',
                              onTap: () => _logic.handleStatusAction(
                                context,
                                liveMedia,
                                'watched',
                                currentStatus,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      AIAnalysisSection(
                        analysisText: storedAnalysis,
                        isAnalyzing: _isAnalyzing,
                        onAnalyzeTap: () async {
                          setState(() => _isAnalyzing = true);
                          await _logic.handleAnalysis(context, liveMedia);
                          if (mounted) setState(() => _isAnalyzing = false);
                        },
                      ),
                      const SizedBox(height: 40),

                      const Text(
                        "SINOSSI",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        overview.isNotEmpty
                            ? overview
                            : "Nessuna trama disponibile.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),

                      WatchProvidersWidget(mediaId: _id, isTvSeries: _isTv),
                      TrailerPlayerWidget(mediaId: _id, isTvSeries: _isTv),
                      MovieCastSection(id: _id, isTvSeries: _isTv),
                      const SizedBox(height: 40),
                      MovieReviewsSection(
                        id: _id,
                        title: title,
                        isTvSeries: _isTv,
                      ),
                      const SizedBox(height: 50),
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

  Widget _buildSliverAppBar(String backdrop, String poster) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      backgroundColor: _backgroundColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: backdrop.isNotEmpty ? backdrop : poster,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: _backgroundColor),
              errorWidget: (_, __, ___) => Container(color: _backgroundColor),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _backgroundColor.withOpacity(0.8),
                    _backgroundColor,
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
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
      height: 45, // Leggermente ridotto per adattarsi a 3
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4), // Padding ridotto
          backgroundColor: isActive
              ? _brandColor
              : Colors.white.withOpacity(0.05),
          foregroundColor: isActive ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ), // Font piccolo per far stare tutto
            ),
          ],
        ),
      ),
    );
  }
}
