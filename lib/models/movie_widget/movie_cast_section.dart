import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import '../../Pages/actor_detail_page.dart'; // <-- Aggiunto l'import della nuova pagina
import 'cast_model.dart';

class MovieCastSection extends StatelessWidget {
  final int id;
  final bool isTvSeries; // Flag per decidere se è un film o una serie TV

  const MovieCastSection({
    super.key,
    required this.id,
    this.isTvSeries = false,
  });

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
          height: 140,
          child: ListenableBuilder(
            listenable: sl<LanguageService>(),
            builder: (context, _) => FutureBuilder<List<CastMember>>(
              key: ValueKey(
                'cast_${id}_${isTvSeries}_${sl<LanguageService>().currentLanguage}',
              ),
              future: isTvSeries
                  ? sl<GetTvSeriesCastUseCase>().call(id)
                  : sl<GetMovieCastUseCase>().call(id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
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
                    return GestureDetector(
                      // <-- AGGIUNTO IL COLLEGAMENTO QUI
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActorDetailPage(actorId: actor.id),
                          ),
                        );
                      },
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 15),
                        color: Colors
                            .transparent, // Assicura che l'area sia cliccabile
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white10),
                                image: actor.fullProfileUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          actor.fullProfileUrl,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.white10,
                              ),
                              child: actor.fullProfileUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white24,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
