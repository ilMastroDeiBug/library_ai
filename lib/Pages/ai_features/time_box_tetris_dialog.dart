import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/ai_repository.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';

// Generi predefiniti (TMDB-like)
const _kGenres = [
  "Azione",
  "Avventura",
  "Animazione",
  "Commedia",
  "Crime",
  "Documentario",
  "Drammatico",
  "Famiglia",
  "Fantasy",
  "Storia",
  "Horror",
  "Musica",
  "Mistero",
  "Romantico",
  "Fantascienza",
  "Thriller",
  "Guerra",
  "Western",
];

class TimeBoxTetrisDialog extends StatefulWidget {
  const TimeBoxTetrisDialog({super.key});

  @override
  State<TimeBoxTetrisDialog> createState() => _TimeBoxTetrisDialogState();
}

class _TimeBoxTetrisDialogState extends State<TimeBoxTetrisDialog> {
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;

  // Step 1: Tempo
  int _minutes = 105; // Default 1h 45m

  // Step 2: Generi
  final Set<String> _selectedGenres = {};

  // Step 3: Tipo
  String _mediaType = 'entrambi'; // 'movie', 'tv', 'entrambi'

  // Step 4: Loading & Risultati
  bool _isLoading = false;
  String? _errorMessage;
  String? _aiMessage;
  List<dynamic> _suggestions = [];

  void _nextStep() {
    // 🟡 FIX #10: Guard contro doppia chiamata
    if (_isLoading) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );

      if (_currentStep == 3) {
        _startCalculation();
      }
    }
  }

  Future<void> _startCalculation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = sl<AuthRepository>().currentUser;
      if (user == null) throw Exception("Non autenticato");

      final payload = {
        "minutes_available": _minutes,
        "genres": _selectedGenres.toList(),
        "media_type": _mediaType,
      };

      final jsonResult = await sl<AiRepository>().callAiFunction(
        user.id,
        'time_box_tetris',
        payload,
        2, // Costo 2 token
      );

      final decoded = jsonDecode(jsonResult);
      final rawSuggestions = decoded['suggestions'] ?? [];

      // Match reale con TMDB per avere veri ID e veri Poster!
      List<dynamic> validSuggestions = [];
      for (var s in rawSuggestions) {
        final title = s['title'];
        final isTv = s['media_type'] == 'tv';
        try {
          if (isTv) {
            final results = await sl<SearchTvSeriesUseCase>().call(title).first;
            if (results.isNotEmpty) {
              final bestMatch = results.first;
              validSuggestions.add({
                'id': bestMatch.id,
                'title': bestMatch.name,
                'media_type': 'tv',
                'poster_path': bestMatch.posterPath,
              });
            } else {
              validSuggestions.add(s); // Fallback
            }
          } else {
            final results = await sl<SearchMoviesUseCase>().call(title).first;
            if (results.isNotEmpty) {
              final bestMatch = results.first;
              validSuggestions.add({
                'id': bestMatch.id,
                'title': bestMatch.title,
                'media_type': 'movie',
                'poster_path': bestMatch.posterPath,
              });
            } else {
              validSuggestions.add(s); // Fallback
            }
          }
        } catch (e) {
          validSuggestions.add(s); // Fallback
        }
      }

      if (mounted) {
        setState(() {
          _aiMessage =
              decoded['ai_message'] ?? "Ecco il tuo incastro perfetto.";
          _suggestions = validSuggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              "Errore durante il calcolo: ${e.toString().replaceAll('Exception: ', '')}";
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return "${m}m";
    if (m == 0) return "${h}h";
    return "${h}h ${m}m";
  }

  void _openMedia(dynamic mediaJson) {
    final isTv = mediaJson['media_type'] == 'tv';
    final id = mediaJson['id'] ?? 0;
    final title = mediaJson['title'] ?? 'Sconosciuto';
    final posterPath = mediaJson['poster_path'] ?? '';

    dynamic mediaObj;
    if (isTv) {
      mediaObj = TvSeries(
        id: id,
        name: title,
        overview: '',
        posterPath: posterPath,
        backdropPath: '',
        firstAirDate: '',
        voteAverage: 0.0,
        popularity: 0.0,
        voteCount: 0,
      );
    } else {
      mediaObj = Movie(
        id: id,
        title: title,
        overview: '',
        posterPath: posterPath,
        backdropPath: '',
        releaseDate: '',
        voteAverage: 0.0,
        popularity: 0.0,
        voteCount: 0,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovieDetailPage(media: mediaObj)),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            width: double.infinity,
            height: 600, // Altezza fissa
            decoration: BoxDecoration(
              color: const Color(0xFF09090B).withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Time-Box Tetris",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                Container(
                  height: 2,
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.05),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_currentStep + 1) / 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.white, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1Time(),
                      _buildStep2Genres(),
                      _buildStep3Format(),
                      _buildStep4Result(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Time() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Quanto tempo hai a disposizione?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Calcoleremo il media perfetto per farti dormire esattamente quando vuoi tu.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            _formatTime(_minutes),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: Colors.white,
              trackHeight: 6,
              overlayColor: Colors.white.withOpacity(0.1),
            ),
            child: Slider(
              value: _minutes.toDouble(),
              min: 15,
              max: 300,
              divisions: (300 - 15) ~/ 5,
              onChanged: (val) {
                setState(() => _minutes = val.toInt());
              },
            ),
          ),
          const Spacer(),
          _buildNextButton("Continua"),
        ],
      ),
    );
  }

  Widget _buildStep2Genres() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            "Che genere preferisci?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Scegli fino a 5 generi.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _kGenres.map((g) {
                  final isSelected = _selectedGenres.contains(g);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedGenres.remove(g);
                        } else if (_selectedGenres.length < 5) {
                          _selectedGenres.add(g);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 15,
                                  spreadRadius: -5,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        g,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildNextButton("Continua", disabled: _selectedGenres.isEmpty),
        ],
      ),
    );
  }

  Widget _buildStep3Format() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            "Formato preferito?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildFormatOption('movie', 'Film', Icons.movie_rounded),
          const SizedBox(height: 16),
          _buildFormatOption('tv', 'Serie TV', Icons.tv_rounded),
          const SizedBox(height: 16),
          _buildFormatOption('entrambi', 'Sorprendimi', Icons.shuffle_rounded),
          const Spacer(),
          _buildNextButton("Inizia Calcolo"),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String value, String title, IconData icon) {
    final isSelected = _mediaType == value;
    return GestureDetector(
      onTap: () => setState(() => _mediaType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Result() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "Sto calcolando il Tetris perfetto...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "L'IA sta assemblando il tuo palinsesto.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Chiudi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Messaggio AI
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    _aiMessage ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Suggerimenti
                if (_suggestions.isNotEmpty) ...[
                  const Text(
                    "Il Tuo Palinsesto",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200, // Altezza per le card orizzontali
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        return GestureDetector(
                          onTap: () => _openMedia(s),
                          child: SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "https://image.tmdb.org/t/p/w500${s['poster_path']}",
                                      fit: BoxFit.cover,
                                      width: 130,
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            child: const Icon(
                                              Icons.movie,
                                              color: Colors.white54,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s['title'] ?? 'Sconosciuto',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s['media_type'] == 'tv' ? 'Serie TV' : 'Film',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Footer (Chiudi)
        Padding(
          padding: const EdgeInsets.all(24),
          child: _buildNextButton("Fantastico, Chiudi", isClose: true),
        ),
      ],
    );
  }

  Widget _buildNextButton(
    String label, {
    bool disabled = false,
    bool isClose = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled
              ? Colors.white.withOpacity(0.1)
              : Colors.white,
          foregroundColor: disabled ? Colors.white54 : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: disabled
            ? null
            : () {
                if (isClose) {
                  Navigator.pop(context);
                } else {
                  _nextStep();
                }
              },
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

void showTimeBoxTetrisModal(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    builder: (context) => const TimeBoxTetrisDialog(),
  );
}
