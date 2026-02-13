import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/movie.dart';
// USE CASES
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
//import 'package:library_ai/domain/use_cases/auth_use_cases.dart'; // Se serve user id

import '../models/ai_analysis_section.dart';
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
  // Stato locale
  late String _currentStatus;
  String? _aiAnalysis;
  bool _isAnalyzing = false;

  static const Color _brandColor =
      Colors.cyanAccent; // O OrangeAccent a tua scelta

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.movie.status; // 'towatch' di default
    _aiAnalysis = widget.movie.aiAnalysis;
  }

  // NUOVA LOGICA: Imposta uno stato specifico
  Future<void> _setStatus(String targetStatus) async {
    // Se lo stato è già quello, non fare nulla (o potresti permettere di deselezionare)
    if (_currentStatus == targetStatus) return;

    final oldStatus = _currentStatus;

    // Aggiornamento Ottimistico UI
    setState(() => _currentStatus = targetStatus);

    try {
      // Usiamo il ToggleUseCase esistente.
      // Poiché sappiamo che stiamo cambiando stato (if sopra), il toggle funzionerà
      // passando da A a B.
      await sl<ToggleMovieStatusUseCase>().call(widget.movie.id, oldStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars(); // Pulisce code vecchie
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              targetStatus == 'watched'
                  ? "✅ Salvato nei film Visti"
                  : "📌 Aggiunto alla Watchlist",
            ),
            backgroundColor: targetStatus == 'watched'
                ? Colors.green
                : _brandColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Rollback in caso di errore
      setState(() => _currentStatus = oldStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Errore di connessione. Riprova.")),
        );
      }
    }
  }

  // LOGICA ANALISI AI
  Future<void> _handleAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await sl<AnalyzeMovieUseCase>().call(
        widget.movie.id,
        widget.movie.title,
      );

      if (mounted) {
        setState(() {
          _aiAnalysis = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore AI: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR CON POSTER
          SliverAppBar(
            expandedHeight: 450, // Più alto per impatto visivo
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
                    widget.movie.fullPosterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
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

          // 2. CONTENUTO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    widget.movie.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  MovieStatsBar(movie: widget.movie),

                  const SizedBox(height: 30),

                  // --- I DUE TASTI SEPARATI ---
                  Row(
                    children: [
                      // TASTO 1: WATCHLIST (DA VEDERE)
                      Expanded(
                        child: _buildActionButton(
                          label: "DA VEDERE",
                          icon: Icons.bookmark_add_outlined,
                          isActive: _currentStatus == 'towatch',
                          activeColor: _brandColor,
                          onTap: () => _setStatus('towatch'),
                        ),
                      ),

                      const SizedBox(width: 15), // Spazio tra i tasti
                      // TASTO 2: WATCHED (VISTO)
                      Expanded(
                        child: _buildActionButton(
                          label: "VISTO",
                          icon: Icons.check_circle_outline,
                          isActive: _currentStatus == 'watched',
                          activeColor:
                              Colors.green, // Verde per il completamento
                          onTap: () => _setStatus('watched'),
                        ),
                      ),
                    ],
                  ),

                  // ----------------------------
                  const SizedBox(height: 40),

                  // SEZIONE AI
                  AIAnalysisSection(
                    analysisText: _aiAnalysis,
                    isAnalyzing: _isAnalyzing,
                    onAnalyzeTap: _handleAnalysis,
                  ),

                  const SizedBox(height: 40),

                  // TRAMA
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
                    widget.movie.overview.isNotEmpty
                        ? widget.movie.overview
                        : "Nessuna trama disponibile.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // CAST
                  MovieCastSection(movieId: widget.movie.id),

                  const SizedBox(height: 40),

                  // RECENSIONI
                  MovieReviewsSection(
                    movieId: widget.movie.id,
                    movieTitle: widget.movie.title,
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

  // Widget helper per creare i bottoni con stile uniforme
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
          elevation: isActive ? 5 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isActive
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isActive ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}
