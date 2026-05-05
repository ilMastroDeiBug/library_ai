import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewAuthorSyncService {
  final SupabaseClient _supabase;

  static const List<String> _cacheBoxNames = [
    'cinelib_cache',
    'tmdb_cache',
  ];

  ReviewAuthorSyncService({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  Future<void> sync({
    required String userId,
    String? author,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    final normalizedAuthor = _readString(author);
    final normalizedAvatarUrl = _readString(avatarUrl);

    if (normalizedAuthor != null) {
      updates['author'] = normalizedAuthor;
    }
    if (normalizedAvatarUrl != null) {
      updates['avatar_url'] = normalizedAvatarUrl;
    }
    if (updates.isEmpty) return;

    await _syncSupabaseReviews(userId, updates);
    await _syncHiveReviews(userId, updates);
  }

  Future<void> _syncSupabaseReviews(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase.from('reviews').update(updates).eq('user_id', userId);
    } on PostgrestException catch (e) {
      print("Errore sync autore recensioni Supabase: ${e.message}");
    } catch (e) {
      print("Errore sync autore recensioni Supabase: $e");
    }
  }

  Future<void> _syncHiveReviews(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    for (final boxName in _cacheBoxNames) {
      if (!Hive.isBoxOpen(boxName)) continue;

      final box = Hive.box(boxName);
      for (final key in box.keys.toList(growable: false)) {
        final cachedValue = box.get(key);
        final mutation = _updateCachedValue(cachedValue, userId, updates);
        if (mutation.changed) {
          await box.put(key, mutation.value);
        }
      }
    }
  }

  _CacheMutation _updateCachedValue(
    Object? value,
    String userId,
    Map<String, dynamic> updates,
  ) {
    if (value is List) {
      var changed = false;
      final nextList = List<dynamic>.from(value);

      for (var i = 0; i < nextList.length; i++) {
        final mutation = _updateCachedValue(nextList[i], userId, updates);
        if (mutation.changed) {
          nextList[i] = mutation.value;
          changed = true;
        }
      }

      return _CacheMutation(value: changed ? nextList : value, changed: changed);
    }

    if (value is Map) {
      var changed = false;
      final nextMap = Map<dynamic, dynamic>.from(value);

      if (_isReviewByUser(nextMap, userId)) {
        _applyReviewAuthorUpdates(nextMap, updates);
        changed = true;
      }

      for (final entry in nextMap.entries.toList(growable: false)) {
        final mutation = _updateCachedValue(entry.value, userId, updates);
        if (mutation.changed) {
          nextMap[entry.key] = mutation.value;
          changed = true;
        }
      }

      return _CacheMutation(value: changed ? nextMap : value, changed: changed);
    }

    return _CacheMutation(value: value, changed: false);
  }

  bool _isReviewByUser(Map<dynamic, dynamic> value, String userId) {
    final rawUserId = value['user_id'] ?? value['userId'];
    if (rawUserId?.toString() != userId) return false;
    return value.containsKey('content') && value.containsKey('rating');
  }

  void _applyReviewAuthorUpdates(
    Map<dynamic, dynamic> value,
    Map<String, dynamic> updates,
  ) {
    if (updates.containsKey('author')) {
      value['author'] = updates['author'];
    }
    if (updates.containsKey('avatar_url')) {
      value['avatar_url'] = updates['avatar_url'];
      if (value.containsKey('avatarUrl')) {
        value['avatarUrl'] = updates['avatar_url'];
      }
    }
  }

  String? _readString(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class _CacheMutation {
  final Object? value;
  final bool changed;

  const _CacheMutation({
    required this.value,
    required this.changed,
  });
}
