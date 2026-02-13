import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_ai/domain/entities/movie.dart';
import '../services/pages_services/movie_detail_service.dart';
import '../models/ai_analysis_section.dart';
// IMPORTIAMO I NUOVI WIDGET MODULARI
import '../models/movie_widget/movie_stats_bar.dart';
import '../models/movie_widget/movie_reviews_section.dart';
import '../models/movie_widget/movie_cast_section.dart';

class MovieDetailPage extends StatefulWidget {
  final Movie movie;
  const MovieDetailPage({super.key, required this.movie});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final MovieDetailService _service = MovieDetailService();
  bool _isAnalyzing = false;

  static const Color _brandColor = Colors.orangeAccent;

  Future<void> _handleStatusToggle(String currentStatus) async {
    try {
      final newStatus = await _service.toggleWatchStatus(
        movie: widget.movie,
        currentStatus: currentStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'watched'
                  ? "Aggiunto ai film visti."
                  : "Aggiunto alla Watchlist.",
            ),
            backgroundColor: newStatus == 'watched'
                ? Colors.green
                : _brandColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Errore: $e")));
      }
    }
  }

  Future<void> _handleAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      await _service.analyzeAndSaveMovie(
        movieId: widget.movie.id,
        title: widget.movie.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Errore analisi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('movies')
          .doc(widget.movie.id.toString())
          .snapshots(),
      builder: (context, snapshot) {
        String currentStatus = 'towatch';
        String? storedAnalysis;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          currentStatus = data['status'] ?? 'towatch';
          storedAnalysis = data['aiAnalysis'];
        }

        final isWatched = currentStatus == 'watched';

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. APP BAR CON SFONDO CINEMA
              SliverAppBar(
                expandedHeight: 350,
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
                        widget.movie.fullBackdropUrl.isNotEmpty
                            ? widget.movie.fullBackdropUrl
                            : widget.movie.fullPosterUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF121212).withOpacity(0.6),
                              const Color(0xFF121212),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. CONTENUTO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITOLO
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: 1.0,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // BARRA STATISTICHE (Modulare)
                      MovieStatsBar(movie: widget.movie),

                      const SizedBox(height: 30),

                      // TASTO AZIONE
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isWatched
                                ? const Color(0xFF1B5E20)
                                : _brandColor,
                            foregroundColor: isWatched
                                ? Colors.white
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () => _handleStatusToggle(currentStatus),
                          icon: Icon(
                            isWatched ? Icons.check : Icons.add_rounded,
                          ),
                          label: Text(
                            isWatched
                                ? "SALVATO NEI VISTI"
                                : "AGGIUNGI ALLA WATCHLIST",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // SEZIONE AI
                      AIAnalysisSection(
                        analysisText: storedAnalysis,
                        isAnalyzing: _isAnalyzing,
                        onAnalyzeTap: _handleAnalysis,
                      ),

                      const SizedBox(height: 30),

                      // TRAMA
                      const Text(
                        "TRAMA",
                        style: TextStyle(
                          color: Colors.white30,
                          letterSpacing: 2.0,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.movie.overview,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // SEZIONE CAST
                      MovieCastSection(movieId: widget.movie.id),

                      const SizedBox(height: 40),

                      // SEZIONE RECENSIONI (Corretta)
                      MovieReviewsSection(
                        movieId: widget.movie.id,
                        movieTitle: widget.movie.title, // <--- Modificato qui
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
}
