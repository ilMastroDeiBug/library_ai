import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import '../services/pages_services/movie_detail_logic.dart';
import '../models/ai_analysis_section.dart';
import '../models/movie_widget/movie_stats_bar.dart';
import '../models/movie_widget/movie_reviews_section.dart';
import '../models/movie_widget/movie_cast_section.dart';

class MovieDetailPage extends StatefulWidget {
  final dynamic media; // Accetta Movie o TvSeries

  const MovieDetailPage({super.key, required this.media});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final MovieDetailLogic _logic = MovieDetailLogic();

  bool _isAnalyzing = false;
  String? _localAnalysis;
  late String _currentStatus;
  static const Color _brandColor = Colors.orangeAccent;

  @override
  void initState() {
    super.initState();
    _localAnalysis = widget.media.aiAnalysis;
    _currentStatus = widget.media.status ?? 'none';
  }

  bool get _isTv => widget.media is TvSeries;

  // Getters per semplificare l'accesso ai dati senza ripetere i cast nel build
  String get _title =>
      _isTv ? (widget.media as TvSeries).name : (widget.media as Movie).title;
  String get _overview => widget.media.overview;
  String get _poster => widget.media.fullPosterUrl;
  String get _backdrop => widget.media.fullBackdropUrl;
  int get _id => widget.media.id;

  @override
  Widget build(BuildContext context) {
    // Adattatore per MovieStatsBar: creiamo un'istanza Movie "al volo" se è TV
    final displayMovieForStats = _isTv
        ? Movie(
            id: _id,
            title: _title,
            overview: _overview,
            posterPath: (widget.media as TvSeries).posterPath,
            backdropPath: (widget.media as TvSeries).backdropPath,
            voteAverage: widget.media.voteAverage,
            voteCount: widget.media.voteCount,
            releaseDate: (widget.media as TvSeries).firstAirDate,
            status: _currentStatus,
          )
        : widget.media as Movie;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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
                    _backdrop.isNotEmpty ? _backdrop : _poster,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[900]),
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MovieStatsBar(movie: displayMovieForStats),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: "DA VEDERE",
                          icon: Icons.bookmark_add_outlined,
                          isActive: _currentStatus == 'towatch',
                          activeColor: _brandColor,
                          onTap: () async {
                            await _logic.handleStatusAction(
                              context,
                              widget.media,
                              'towatch',
                              _currentStatus,
                            );
                            setState(
                              () => _currentStatus = _currentStatus == 'towatch'
                                  ? 'none'
                                  : 'towatch',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          label: "VISTO",
                          icon: Icons.check_circle_outline,
                          isActive: _currentStatus == 'watched',
                          activeColor: Colors.green,
                          onTap: () async {
                            await _logic.handleStatusAction(
                              context,
                              widget.media,
                              'watched',
                              _currentStatus,
                            );
                            setState(
                              () => _currentStatus = _currentStatus == 'watched'
                                  ? 'none'
                                  : 'watched',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  AIAnalysisSection(
                    analysisText: _localAnalysis,
                    isAnalyzing: _isAnalyzing,
                    onAnalyzeTap: () async {
                      setState(() => _isAnalyzing = true);
                      final res = await _logic.handleAnalysis(
                        context,
                        widget.media,
                      );
                      if (mounted) {
                        setState(() {
                          _localAnalysis = res;
                          _isAnalyzing = false;
                        });
                      }
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
                    _overview.isNotEmpty
                        ? _overview
                        : "Nessuna trama disponibile.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  MovieCastSection(id: _id, isTvSeries: _isTv),
                  const SizedBox(height: 40),
                  MovieReviewsSection(
                    id: _id,
                    title: _title,
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
