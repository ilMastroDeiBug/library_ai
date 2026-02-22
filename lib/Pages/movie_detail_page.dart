import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import '../services/pages_services/movie_detail_logic.dart';
import '../models/ai_analysis_section.dart';
import '../models/movie_widget/movie_stats_bar.dart';
import '../models/movie_widget/movie_reviews_section.dart';
import '../models/movie_widget/movie_cast_section.dart';
import '../models/movie_widget/trailer_player_widget.dart';
import '../models/movie_widget/watch_provider_widgets.dart'; // <-- IMPORT WIDGET PROVIDERS

class MovieDetailPage extends StatefulWidget {
  final dynamic media; // Movie o TvSeries
  const MovieDetailPage({super.key, required this.media});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final MovieDetailLogic _logic = MovieDetailLogic();
  bool _isAnalyzing = false;
  static const Color _brandColor = Colors.orangeAccent;

  bool get _isTv => widget.media is TvSeries;
  int get _id => widget.media.id;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('watchlist')
                .doc(_id.toString())
                .snapshots()
          : null,
      builder: (context, snapshot) {
        dynamic liveMedia = widget.media;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (_isTv) {
            liveMedia = TvSeries.fromFirestore(data, _id);
          } else {
            liveMedia = Movie.fromFirestore(data, _id);
          }
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
                status: currentStatus,
              )
            : liveMedia as Movie;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
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
                      // 1. Titolo
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Bar delle statistiche
                      MovieStatsBar(movie: displayMovieForStats),
                      const SizedBox(height: 30),

                      // 3. Bottoni d'azione
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: "DA VEDERE",
                              icon: Icons.bookmark_add_outlined,
                              isActive: currentStatus == 'towatch',
                              activeColor: _brandColor,
                              onTap: () => _logic.handleStatusAction(
                                context,
                                liveMedia,
                                'towatch',
                                currentStatus,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildActionButton(
                              label: "VISTO",
                              icon: Icons.check_circle_outline,
                              isActive: currentStatus == 'watched',
                              activeColor: Colors.green,
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

                      // 4. Sezione Analisi AI
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

                      // 5. Sinossi
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

                      // 6. WATCH PROVIDERS WIDGET (I loghi di Netflix, Amazon, ecc.)
                      WatchProvidersWidget(mediaId: _id, isTvSeries: _isTv),

                      // 7. TRAILER WIDGET
                      TrailerPlayerWidget(mediaId: _id, isTvSeries: _isTv),

                      // 8. Cast
                      MovieCastSection(id: _id, isTvSeries: _isTv),
                      const SizedBox(height: 40),

                      // 9. Recensioni
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
      backgroundColor: const Color(0xFF121212),
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
            Image.network(
              backdrop.isNotEmpty ? backdrop : poster,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF121212).withOpacity(0.8),
                    const Color(0xFF121212),
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
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? activeColor
              : Colors.white.withOpacity(0.05),
          foregroundColor: isActive ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}
