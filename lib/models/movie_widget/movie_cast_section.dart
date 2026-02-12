import 'package:flutter/material.dart';
import '../../services/utility_services/tmdb_service.dart';
import 'cast_model.dart';

class MovieCastSection extends StatelessWidget {
  final int movieId;
  final TmdbService _tmdbService = TmdbService();

  MovieCastSection({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CAST",
          style: TextStyle(
            color: Colors.white30,
            letterSpacing: 2.0,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 140, // Altezza fissa per lo scroll orizzontale
          child: FutureBuilder<List<CastMember>>(
            future: _tmdbService.fetchMovieCast(
              movieId,
            ), // Metodo da aggiungere
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Text(
                  "Info cast non disponibili.",
                  style: TextStyle(color: Colors.white24),
                );
              }

              final cast = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cast.length,
                itemBuilder: (context, index) {
                  final actor = cast[index];
                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        // Foto Attore
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white10),
                            image: actor.fullProfileUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(actor.fullProfileUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.white10, // Sfondo se non c'è foto
                          ),
                          child: actor.fullProfileUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.white24)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        // Nome
                        Text(
                          actor.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Ruolo
                        Text(
                          actor.character,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
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
