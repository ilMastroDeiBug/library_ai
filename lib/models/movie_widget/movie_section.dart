import 'package:flutter/material.dart';
import '/services/utility_services/tmdb_service.dart';
import '../../models/movie_widget/movie_model.dart';
import 'movie_card.dart';
// 1. IMPORTIAMO LA PAGINA DI DETTAGLIO
import '../../pages/movie_detail_page.dart';

class MovieSection extends StatelessWidget {
  final String title;
  final String categoryPath; // Es: "movie/popular" o "discover/movie?..."
  final TmdbService _tmdbService = TmdbService();

  MovieSection({super.key, required this.title, required this.categoryPath});

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
                title,
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
          height: 180, // Altezza del poster
          child: FutureBuilder<List<Movie>>(
            future: _tmdbService.fetchByCategory(categoryPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
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
                    "Nessun film trovato",
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }

              final movies = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.only(left: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];

                  // 2. IL TRUCCO: AVVOLGIAMO LA CARD NEL GESTURE DETECTOR
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailPage(movie: movie),
                        ),
                      );
                    },
                    child: MovieCard(movie: movie),
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
