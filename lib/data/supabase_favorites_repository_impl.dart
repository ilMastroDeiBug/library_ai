import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/repositories/favorite_repository.dart';
import '../domain/entities/favorite_item.dart';

class SupabaseFavoritesRepositoryImpl implements FavoritesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'favorites';

  @override
  Future<bool> toggleFavorite(
    String userId,
    int itemId,
    String itemType,
    String title,
    String? posterUrl,
  ) async {
    // 1. Controlla se è già nei preferiti
    final existing = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('item_id', itemId)
        .eq('item_type', itemType)
        .maybeSingle();

    if (existing != null) {
      // 2a. Se esiste, rimuovilo
      await _supabase.from(_tableName).delete().eq('id', existing['id']);
      return false;
    } else {
      // 2b. Se non esiste, salvalo
      await _supabase.from(_tableName).insert({
        'user_id': userId,
        'item_id': itemId,
        'item_type': itemType,
        'title': title,
        'poster_url': posterUrl,
      });
      return true;
    }
  }

  @override
  Stream<List<FavoriteItem>> getFavoritesStream(String userId, {String? type}) {
    // 1. Apriamo lo stream dicendo a Supabase che 'id' è la chiave primaria
    // per tracciare correttamente gli aggiornamenti in tempo reale.
    var query = _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return query.map((snapshot) {
      // 2. Se c'è un filtro 'type' (es. voglio solo i film)
      if (type != null) {
        // Applichiamo il filtro in memoria.
        // Nota: Creiamo esplicitamente una NUOVA lista con .toList()
        // così Flutter capisce che lo stato è cambiato.
        final filtered = snapshot
            .where((row) => row['item_type'] == type)
            .toList();
        return filtered.map((row) => FavoriteItem.fromMap(row)).toList();
      }

      // 3. Se non c'è filtro, mappiamo tutti i risultati
      return snapshot.map((row) => FavoriteItem.fromMap(row)).toList();
    });
  }

  @override
  Stream<bool> isFavoriteStream(String userId, int itemId, String itemType) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId) // <-- L'unico filtro permesso lato server
        .map((snapshot) {
          // Filtriamo il resto lato client nella memoria dell'app (velocissimo)
          final matches = snapshot.where(
            (row) => row['item_id'] == itemId && row['item_type'] == itemType,
          );
          return matches.isNotEmpty;
        });
  }
}
