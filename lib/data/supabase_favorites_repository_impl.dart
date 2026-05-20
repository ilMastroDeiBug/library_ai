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

    final isAdded = existing == null;

    if (!isAdded) {
      await _supabase.from(_tableName).delete().eq('id', existing['id']);
    } else {
      await _supabase.from(_tableName).insert({
        'user_id': userId,
        'item_id': itemId,
        'item_type': itemType,
        'title': title,
        'poster_url': posterUrl,
      });
    }

    // FIX CHIAVE: Sincronizziamo la Cache locale in modo che le Detail Pages
    // abbiano sempre la risposta corretta immediata!
    final cacheBox = Hive.box('cinelib_cache');
    final cacheKey = 'favorites_${userId}_$itemType';
    final cachedList = cacheBox.get(cacheKey);

    if (cachedList is List) {
      var list = cachedList.map((e) => Map<String, dynamic>.from(e)).toList();
      if (isAdded) {
        list.insert(0, {
          'user_id': userId,
          'item_id': itemId,
          'item_type': itemType,
          'title': title,
          'poster_url': posterUrl,
        });
      } else {
        list.removeWhere((e) => e['item_id'] == itemId);
      }
      await cacheBox.put(cacheKey, list);
    }

    return isAdded;
  }

  final Map<String, Stream<List<FavoriteItem>>> _activeStreams = {};

  @override
  Stream<List<FavoriteItem>> getFavoritesStream(
    String userId, {
    String? type,
  }) {
    final streamKey = type == null ? 'favorites_$userId' : 'favorites_${userId}_$type';
    
    if (_activeStreams.containsKey(streamKey)) {
      return _activeStreams[streamKey]!;
    }

    final stream = _createFavoritesStream(userId, type: type).asBroadcastStream(
      onCancel: (sub) => _activeStreams.remove(streamKey),
    );
    _activeStreams[streamKey] = stream;
    return stream;
  }

  Stream<List<FavoriteItem>> _createFavoritesStream(
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

    if (!sl<NetworkStatusService>().isOnline) return;

    try {
      final snapshot = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

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
          await cacheBox.put('favorites_${userId}_${entry.key}', entry.value);
        }
      }

      yield _mapFavoriteRowsToEntities(filteredRows, type: type);
    } catch (_) {}
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
