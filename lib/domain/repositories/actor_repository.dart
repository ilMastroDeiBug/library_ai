import '../entities/actor.dart';
import '../../models/movie_widget/cast_model.dart'; // Importa CastMember

abstract class ActorRepository {
  /// Recupera i dettagli completi di un attore, inclusa la sua filmografia
  Future<Actor> getActorDetails(int actorId);

  /// Cerca attori per nome restituendo una lista di CastMember per la SearchPage
  Future<List<CastMember>> searchActors(String query);
}
