import '../entities/actor.dart';
import '../repositories/actor_repository.dart';
import '../../models/movie_widget/cast_model.dart';

class GetActorDetailsUseCase {
  final ActorRepository repository;

  GetActorDetailsUseCase(this.repository);

  Future<Actor> call(int actorId) async {
    return await repository.getActorDetails(actorId);
  }
}

class SearchActorsUseCase {
  final ActorRepository repository;

  SearchActorsUseCase(this.repository);

  Future<List<CastMember>> call(String query) async {
    return await repository.searchActors(query);
  }
}
