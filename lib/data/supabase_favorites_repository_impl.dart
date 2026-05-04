import 'package:hive/hive.dart';
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
    final existing = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('item_id', itemId)
        .eq('item_type', itemType)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from(_tableName).delete().eq('id', existing['id']);
      return false;
    }

    await _supabase.from(_tableName).insert({
      'user_id': userId,
      'item_id': itemId,
      'item_type': itemType,
      'title': title,
      'poster_url': posterUrl,
    });
    return true;
  }

  @override
  Stream<List<FavoriteItem>> getFavoritesStream(
    String userId, {
    String? type,
  }) async* {
    final cacheKey = type == null
        ? 'favorites_$userId'
        : 'favorites_${userId}_$type';
    final cacheBox = Hive.box('cinelib_cache');

    final cachedRows = _readCachedRows(cacheBox, cacheKey);
    if (cachedRows != null) {
      yield _mapFavoriteRowsToEntities(cachedRows, type: type);
    } else if (type != null) {
      final cachedAllRows = _readCachedRows(cacheBox, 'favorites_$userId');
      if (cachedAllRows != null) {
        yield _mapFavoriteRowsToEntities(cachedAllRows, type: type);
      }
    }

    try {
      yield* _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .asyncMap((snapshot) async {
            final rows = snapshot
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
            final filteredRows = type == null
                ? rows
                : rows.where((row) => row['item_type'] == type).toList();

            await cacheBox.put(cacheKey, filteredRows);
            if (type == null) {
              final groupedByType = <String, List<Map<String, dynamic>>>{};
              for (final row in rows) {
                final rowType = row['item_type']?.toString();
                if (rowType == null) continue;
                groupedByType.putIfAbsent(rowType, () => []).add(row);
              }

              for (final entry in groupedByType.entries) {
                await cacheBox.put(
                  'favorites_${userId}_${entry.key}',
                  entry.value,
                );
              }
            }

            return _mapFavoriteRowsToEntities(filteredRows, type: type);
          });
    } catch (_) {
      // Offline o errore realtime: la UI continua a usare l'ultimo yield cache.
    }
  }

  @override
  Stream<bool> isFavoriteStream(String userId, int itemId, String itemType) {
    return getFavoritesStream(userId, type: itemType).map((items) {
      return items.any((item) => item.itemId == itemId);
    });
  }

  List<Map<String, dynamic>>? _readCachedRows(Box cacheBox, String cacheKey) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! List) return null;

    return cached
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  List<FavoriteItem> _mapFavoriteRowsToEntities(
    List<Map<String, dynamic>> rows, {
    String? type,
  }) {
    final filteredRows = type == null
        ? rows
        : rows.where((row) => row['item_type'] == type).toList();

    return filteredRows.map((row) => FavoriteItem.fromMap(row)).toList();
  }
}
