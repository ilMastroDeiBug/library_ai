import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/repositories/favorite_repository.dart';
import '../domain/entities/favorite_item.dart';
import 'package:library_ai/services/utility_services/network_status_service.dart';
import 'package:library_ai/injection_container.dart';

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

    // 1. CARICHIAMO E MOSTRIAMO SUBITO LA CACHE
    final cachedRows = _readCachedRows(cacheBox, cacheKey);
    bool hasCache = false;

    if (cachedRows != null) {
      hasCache = cachedRows.isNotEmpty;
      yield _mapFavoriteRowsToEntities(cachedRows, type: type);
    } else if (type != null) {
      // Se non abbiamo la cache specifica, cerchiamo in quella generale
      final cachedAllRows = _readCachedRows(cacheBox, 'favorites_$userId');
      if (cachedAllRows != null) {
        hasCache = cachedAllRows.isNotEmpty;
        yield _mapFavoriteRowsToEntities(cachedAllRows, type: type);
      }
    }

    // 2. SE SIAMO OFFLINE, FERMIAMOCI ALLA CACHE
    if (!sl<NetworkStatusService>().isOnline) return;

    // 3. AGGIORNAMENTO DA SUPABASE PROTETTO
    try {
      final supabaseStream = _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      bool isFirstEvent = true;

      await for (final snapshot in supabaseStream) {
        final rows = snapshot
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

        final filteredRows = type == null
            ? rows
            : rows.where((row) => row['item_type'] == type).toList();

        // FIX CRITICO DEL MILLISECONDO:
        // Supabase spara un array vuoto [] appena si connette.
        // Se abbiamo la cache, ignoriamo questo "falso vuoto".
        if (isFirstEvent && filteredRows.isEmpty && hasCache) {
          isFirstEvent = false;
          continue;
        }
        isFirstEvent = false;

        // Salvataggio in cache solo di dati reali e validi
        await cacheBox.put(cacheKey, filteredRows);

        if (type == null) {
          final groupedByType = <String, List<Map<String, dynamic>>>{};
          for (final row in rows) {
            final rowType = row['item_type']?.toString();
            if (rowType == null) continue;
            groupedByType.putIfAbsent(rowType, () => []).add(row);
          }

          for (final entry in groupedByType.entries) {
            await cacheBox.put('favorites_${userId}_${entry.key}', entry.value);
          }
        }

        yield _mapFavoriteRowsToEntities(filteredRows, type: type);
      }
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
