import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/repositories/ai_repository.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';

const _kVibes = [
  "Rilassante", "Adrenalinica", "Misteriosa", "Strappalacrime", 
  "Comica", "Dark", "Spensierata", "Cerebrale"
];

const _kLengths = [
  "Corta/Mini-serie", "Media (2-3 Stagioni)", "Lunga (4+ Stagioni)", "Film secco"
];

const _kTwists = [
  "Finali aperti", "Nessun colpo di scena", "Plot twist continui", "Cattivi che vincono"
];

const _kFormats = [
  "Solo Serie TV", "Solo Film", "Entrambe"
];

class WhatToWatchNextDialog extends StatefulWidget {
  final dynamic item;
  const WhatToWatchNextDialog({super.key, this.item});

  @override
  State<WhatToWatchNextDialog> createState() => _WhatToWatchNextDialogState();
}

class _WhatToWatchNextDialogState extends State<WhatToWatchNextDialog> {
  final PageController _pageCtrl = PageController();
  late int _currentStep;
  late int _maxSteps;
  
  dynamic _selectedItem;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _trendingResults = [];
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  Timer? _debounce;

  // Form
  String _selectedVibe = '';
  String _selectedLength = '';
  String _selectedTwist = '';
  String _selectedFormat = 'Entrambe'; // Default
  final TextEditingController _customTextCtrl = TextEditingController();

  // Result
  bool _isLoading = false;
  String? _errorMessage;
  String? _aiMessage;
  List<dynamic> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.item;
    // Se c'è l'item partiamo dallo step Form, altrimenti dalla Ricerca
    if (_selectedItem != null) {
      _currentStep = 1;
    } else {
      _currentStep = 0;
      _loadTrending();
    }
    _maxSteps = 3; // 0=Search, 1=Form, 2=Result
    // Post frame to start at step 1 if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentStep == 1) {
        _pageCtrl.jumpToPage(1);
      }
    });
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoadingTrending = true);
    try {
      final movies = await sl<GetMoviesByCategoryUseCase>().call('trending').first;
      final tvs = await sl<GetTvSeriesByCategoryUseCase>().call('trending').first;
      
      final combined = [...movies, ...tvs]
        ..shuffle();
        
      if (mounted) {
        setState(() {
          _trendingResults = combined;
          _isLoadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTrending = false);
    }
  }

  String get _mediaTitle {
    if (_selectedItem == null) return "Sconosciuto";
    if (_selectedItem is TvSeries) return (_selectedItem as TvSeries).name;
    if (_selectedItem is Movie) return (_selectedItem as Movie).title;
    if (_selectedItem is Book) return (_selectedItem as Book).title;
    try {
      return _selectedItem.title;
    } catch (_) {
      try {
        return _selectedItem.name;
      } catch (_) {
        return "Sconosciuto";
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        return;
      }

      setState(() => _isSearching = true);
      
      try {
        final movies = await sl<SearchMoviesUseCase>().call(query).first;
        final tvs = await sl<SearchTvSeriesUseCase>().call(query).first;
        
        final combined = [...movies.take(5), ...tvs.take(5)]
            ..sort((a, b) {
              final num popA = (a as dynamic).popularity ?? 0.0;
              final num popB = (b as dynamic).popularity ?? 0.0;
              return popB.compareTo(popA);
            });

        if (mounted) {
          setState(() {
            _searchResults = combined;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      
      if (_currentStep == 2) {
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
        "finished_title": _mediaTitle,
        "vibe": _selectedVibe,
        "length": _selectedLength,
        "twist": _selectedTwist,
        "target_format": _selectedFormat,
        "custom_text": _customTextCtrl.text,
      };

      final jsonResult = await sl<AiRepository>().callAiFunction(
        user.id,
        'what_to_watch_next',
        payload,
        2, // Costo 2 token
      );

      final decoded = jsonDecode(jsonResult);
      final rawSuggestions = decoded['suggestions'] ?? [];
      
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
                'reason': s['reason'] ?? '',
              });
            } else {
              validSuggestions.add(s);
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
                'reason': s['reason'] ?? '',
              });
            } else {
              validSuggestions.add(s);
            }
          }
        } catch (e) {
          validSuggestions.add(s);
        }
      }

      if (mounted) {
        setState(() {
          _aiMessage = decoded['ai_message'] ?? "Ecco cosa guardare dopo.";
          _suggestions = validSuggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Errore durante il calcolo: ${e.toString().replaceAll('Exception: ', '')}";
          _isLoading = false;
        });
      }
    }
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
    _customTextCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
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
            height: 700, 
            decoration: BoxDecoration(
              color: const Color(0xFF09090B).withOpacity(0.85),
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
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Cosa guardare dopo?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
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
                    widthFactor: (_currentStep + 1) / _maxSteps,
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
                      _buildStep0Search(),
                      _buildStep1Form(),
                      _buildStep2Result(),
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

  Widget _buildStep0Search() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            "Che cos'hai appena finito di guardare?",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: "Cerca un film o una serie TV...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching || _isLoadingTrending
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : (_searchCtrl.text.isEmpty ? _trendingResults : _searchResults).isEmpty
                    ? const Center(
                        child: Text(
                          "Nessun risultato trovato",
                          style: TextStyle(color: Colors.white30, fontSize: 14),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: (_searchCtrl.text.isEmpty ? _trendingResults : _searchResults).length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final currentList = _searchCtrl.text.isEmpty ? _trendingResults : _searchResults;
                          final res = currentList[index];
                          final bool isTv = res is TvSeries;
                          final title = isTv ? res.name : (res as Movie).title;
                          final poster = isTv ? res.fullPosterUrl : (res as Movie).fullPosterUrl;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedItem = res;
                              });
                              _nextStep();
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: poster,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.white.withOpacity(0.1),
                                      child: const Icon(Icons.movie, color: Colors.white24),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0, left: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                        ),
                                      ),
                                      child: Text(
                                        title,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
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
      ),
    );
  }

  Widget _buildStep1Form() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.5),
              children: [
                const TextSpan(text: "Stai per finire "),
                TextSpan(text: '"$_mediaTitle"', style: const TextStyle(fontWeight: FontWeight.w800)),
                const TextSpan(text: ". Cosa vorresti dalla prossima visione?"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Formato Desiderato", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _kFormats.map((f) => _buildChip(f, _selectedFormat, (val) => setState(() => _selectedFormat = val))).toList(),
                  ),
                  const SizedBox(height: 20),

                  const Text("La Vibe", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _kVibes.map((v) => _buildChip(v, _selectedVibe, (val) => setState(() => _selectedVibe = val))).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text("La Lunghezza", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _kLengths.map((l) => _buildChip(l, _selectedLength, (val) => setState(() => _selectedLength = val))).toList(),
                  ),
                  const SizedBox(height: 20),

                  const Text("Dinamica", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _kTwists.map((t) => _buildChip(t, _selectedTwist, (val) => setState(() => _selectedTwist = val))).toList(),
                  ),
                  const SizedBox(height: 20),

                  const Text("Tocchi personali (Opzionale)", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customTextCtrl,
                    maxLength: 300,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Es: Vorrei qualcosa ambientato nello spazio...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildNextButton("Suggerisci Titoli", disabled: _selectedVibe.isEmpty || _selectedLength.isEmpty),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String groupValue, Function(String) onSelect) {
    final isSelected = groupValue == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Result() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "Sto interrogando l'Oracolo...",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "L'IA sta cercando le tue prossime ossessioni.",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            )
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
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Chiudi", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: _suggestions.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
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
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                );
              }

              final s = _suggestions[index - 1];
              return _buildVerticalSuggestionCard(s);
            },
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

  Widget _buildVerticalSuggestionCard(dynamic s) {
    return GestureDetector(
      onTap: () => _openMedia(s),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: "https://image.tmdb.org/t/p/w500${s['poster_path']}",
                fit: BoxFit.cover,
                width: 80,
                height: 120,
                errorWidget: (context, url, error) => Container(
                  width: 80, height: 120,
                  color: Colors.white.withOpacity(0.1),
                  child: const Icon(Icons.movie, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['title'] ?? 'Sconosciuto',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s['media_type'] == 'tv' ? 'SERIE TV' : 'FILM',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['reason'] ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(String label, {bool disabled = false, bool isClose = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.white.withOpacity(0.1) : Colors.white,
          foregroundColor: disabled ? Colors.white54 : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

void showWhatToWatchNextModal(BuildContext context, dynamic item) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    builder: (context) => WhatToWatchNextDialog(item: item),
  );
}
