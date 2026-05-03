import '../repositories/favorite_repository.dart';
import '../entities/favorite_item.dart';

class ToggleFavoriteUseCase {
  final FavoritesRepository repository;
  ToggleFavoriteUseCase(this.repository);

  Future<bool> call(
    String userId,
    int itemId,
    String itemType,
    String title,
    String? posterUrl,
  ) {
    return repository.toggleFavorite(
      userId,
      itemId,
      itemType,
      title,
      posterUrl,
    );
  }
}

class GetFavoritesStreamUseCase {
  final FavoritesRepository repository;
  GetFavoritesStreamUseCase(this.repository);

  Stream<List<FavoriteItem>> call(String userId, {String? type}) {
    return repository.getFavoritesStream(userId, type: type);
  }
}

class CheckFavoriteStatusUseCase {
  final FavoritesRepository repository;
  CheckFavoriteStatusUseCase(this.repository);

  Stream<bool> call(String userId, int itemId, String itemType) {
    return repository.isFavoriteStream(userId, itemId, itemType);
  }
}
