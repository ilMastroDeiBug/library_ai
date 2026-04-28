import '../domain/entities/actor.dart';
import '../domain/repositories/actor_repository.dart';
import '../services/utility_services/tmdb_service.dart';
import '../../models/movie_widget/cast_model.dart'; // <-- IMPORTANTE: Aggiunto il modello leggero

class TmdbActorRepositoryImpl implements ActorRepository {
  final TmdbService tmdbService;

  TmdbActorRepositoryImpl({required this.tmdbService});

  @override
  Future<Actor> getActorDetails(int actorId) async {
    try {
      final data = await tmdbService.getPersonDetails(actorId);

      // Parsing dei credits (unendo film e serie tv)
      List<ActorCredit> parsedCredits = [];
      if (data['combined_credits'] != null &&
          data['combined_credits']['cast'] != null) {
        final castList = data['combined_credits']['cast'] as List;

        for (var item in castList) {
          // Salta i ruoli senza immagine per mantenere la UI pulita
          if (item['poster_path'] == null) continue;

          parsedCredits.add(
            ActorCredit(
              id: item['id'],
              title: item['title'] ?? item['name'] ?? 'Titolo Sconosciuto',
              posterPath: item['poster_path'],
              mediaType: item['media_type'] ?? 'movie',
              voteAverage: (item['vote_average'] ?? 0).toDouble(),
              character: item['character'],
              releaseDate: item['release_date'] ?? item['first_air_date'],
            ),
          );
        }

        // Ordina i film dal più recente al più vecchio
        parsedCredits.sort((a, b) {
          if (a.releaseDate == null) return 1;
          if (b.releaseDate == null) return -1;
          return b.releaseDate!.compareTo(a.releaseDate!);
        });
      }

      return Actor(
        id: data['id'],
        name: data['name'] ?? 'Nome Sconosciuto',
        biography: data['biography'] ?? 'Nessuna biografia disponibile.',
        profilePath: data['profile_path'],
        birthday: data['birthday'],
        deathday: data['deathday'],
        placeOfBirth: data['place_of_birth'],
        popularity: (data['popularity'] ?? 0).toDouble(),
        knownForDepartment: data['known_for_department'] ?? 'Acting',
        credits: parsedCredits,
      );
    } catch (e) {
      throw Exception('Errore durante il parsing dei dettagli attore: $e');
    }
  }

  @override
  Future<List<CastMember>> searchActors(String query) async {
    // Ora chiama l'API vera invece di tirare un errore!
    return await tmdbService.searchActors(query);
  }
}
