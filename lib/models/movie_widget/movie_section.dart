import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import 'movie_card.dart';
import '../../pages/movie_detail_page.dart';

class MovieSection extends StatefulWidget {
  final String title;
  final String categoryPath;
  final bool isTvSeries;

  const MovieSection({
    super.key,
    required this.title,
    required this.categoryPath,
    this.isTvSeries = false,
  });

  @override
  State<MovieSection> createState() => _MovieSectionState();
}

class _MovieSectionState extends State<MovieSection> {
  late Stream<List<dynamic>> _stream;
  final LanguageService _languageService = sl<LanguageService>();

  @override
  void initState() {
    super.initState();
    _stream = _fetchItems();
    _languageService.addListener(_handleLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  Stream<List<dynamic>> _fetchItems() {
    // FIX: Uso sicuro di List<dynamic>.from() invece di cast()
    return widget.isTvSeries
        ? sl<GetTvSeriesByCategoryUseCase>()
              .call(widget.categoryPath)
              .map((items) => List<dynamic>.from(items))
        : sl<GetMoviesByCategoryUseCase>()
              .call(widget.categoryPath)
              .map((items) => List<dynamic>.from(items));
  }

  void _handleLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _stream = _fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo Sezione
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: Colors.orangeAccent,
                size: 18,
              ),
            ],
          ),
        ),

        // Lista Orizzontale
        SizedBox(
          height: 200,
          child: StreamBuilder<List<dynamic>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white24,
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "Errore caricamento",
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "Nessun contenuto",
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }

              final list = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.only(left: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];

                  return MovieCard(
                    media: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailPage(media: item),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
