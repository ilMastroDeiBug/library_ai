import '../entities/favorite_item.dart';

abstract class FavoritesRepository {
  /// Aggiunge o rimuove un preferito (ritorna true se è stato aggiunto, false se rimosso)
  Future<bool> toggleFavorite(
    String userId,
    int itemId,
    String itemType,
    String title,
    String? posterUrl,
  );

  /// Recupera tutti i preferiti. Se [type] è specificato, filtra per tipo.
  Stream<List<FavoriteItem>> getFavoritesStream(String userId, {String? type});

  /// Restituisce uno stream per ascoltare se un singolo item è tra i preferiti (utile per l'icona a cuore)
  Stream<bool> isFavoriteStream(String userId, int itemId, String itemType);
}
