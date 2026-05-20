import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:library_ai/domain/repositories/social_repository.dart';
import 'package:library_ai/domain/entities/pinned_item.dart';
import 'package:library_ai/domain/entities/vault_entry.dart';
import 'package:library_ai/domain/entities/social_stats.dart';
import 'package:library_ai/domain/entities/app_user.dart';

/// Implementazione concreta di [SocialRepository] che usa Supabase come backend.
///
/// Tabelle attese:
///   - `follows`       (id, follower_id, following_id, created_at)
///   - `pinned_items`  (id, user_id, media_id, media_type, title, poster_url, position, created_at)
///   - `user_media`    (vista unificata o tabella che aggrega film/serie/libri per un utente)
///   - `profiles`      (già esistente nell'app)
class SupabaseSocialRepositoryImpl implements SocialRepository {
  final SupabaseClient _supabase;

  SupabaseSocialRepositoryImpl({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  // ── Statistiche ────────────────────────────────────────────────────────────

  @override
  Future<SocialStats> getSocialStats(String userId) async {
    // 1. Prova RPC Supabase (calcolo server-side, zero egress)
    try {
      final response = await _supabase.rpc(
        'get_user_watch_stats',
        params: {'user_uuid': userId},
      );
      if (response != null) {
        return SocialStats.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      // RPC non disponibile → calcola localmente da Hive
    }

    // 2. Fallback: calcolo locale leggendo raw_data dalla cache Hive
    return _computeStatsFromHive(userId);
  }

  /// Calcola le statistiche direttamente dalla cache Hive locale.
  /// Nessuna chiamata di rete. Usato come fallback se la RPC non è disponibile.
  SocialStats _computeStatsFromHive(String userId) {
    if (!Hive.isBoxOpen('cinelib_cache')) return const SocialStats();
    final box = Hive.box('cinelib_cache');

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    int moviesCount = 0;
    int tvCount = 0;
    int watchlistCount = 0;
    int totalMinutes = 0;
    int weekMinutes = 0;
    int monthMinutes = 0;
    int yearMinutes = 0;

    // Legge le liste dalla cache (chiavi: watchlist_{userId}_{status})
    for (final status in ['watched', 'watching', 'towatch', 'favorites']) {
      final cached = box.get('watchlist_${userId}_$status');
      if (cached is! List) continue;

      for (final raw in cached) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final type = row['type']?.toString() ?? 'movie';
        final rowStatus = row['status']?.toString() ?? status;

        final rawData = row['raw_data'] is Map
            ? Map<String, dynamic>.from(row['raw_data'] as Map)
            : <String, dynamic>{};

        // Contatori
        if (rowStatus == 'watched') {
          if (type == 'movie') moviesCount++;
          if (type == 'tv') tvCount++;
        }
        if (rowStatus == 'watching' || rowStatus == 'towatch') {
          watchlistCount++;
        }

        // Minutaggio (solo watched + watching)
        if (rowStatus != 'watched' && rowStatus != 'watching') continue;

        int mins = 0;
        if (type == 'movie' && rowStatus == 'watched') {
          final rt = _parseInt(rawData['runtime']);
          mins = rt > 0 ? rt : 120;
        } else if (type == 'tv') {
          final epRt = _parseInt(rawData['runtime']);
          final epRuntime = epRt > 0 ? epRt : 45;
          if (rowStatus == 'watched') {
            final nEp = _parseInt(rawData['number_of_episodes']);
            mins = epRuntime * (nEp > 0 ? nEp : 10);
          }
          // 'watching': non contiamo qui senza tv_progress locale
        }

        if (mins == 0) continue;

        DateTime? ts;
        try {
          final tsStr = row['timestamp']?.toString();
          if (tsStr != null) ts = DateTime.tryParse(tsStr);
        } catch (_) {}

        totalMinutes += mins;
        if (ts != null) {
          if (ts.isAfter(startOfYear)) yearMinutes += mins;
          if (ts.isAfter(startOfMonth)) monthMinutes += mins;
          if (ts.isAfter(startOfWeek)) weekMinutes += mins;
        }
      }
    }

    // Contatori follow (se disponibili)
    int followersCount = 0;
    int followingCount = 0;
    try {
      followersCount = (box.get('followers_count_$userId') as int?) ?? 0;
      followingCount = (box.get('following_count_$userId') as int?) ?? 0;
    } catch (_) {}

    return SocialStats(
      followersCount: followersCount,
      followingCount: followingCount,
      moviesCount: moviesCount,
      tvCount: tvCount,
      vaultCount: moviesCount + tvCount,
      totalMinutes: totalMinutes,
      weekMinutes: weekMinutes,
      monthMinutes: monthMinutes,
      yearMinutes: yearMinutes,
      watchlistCount: watchlistCount,
    );
  }

  int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  // ── Vetrina (Pinned Items) ─────────────────────────────────────────────────

  @override
  Stream<List<PinnedItem>> getPinnedItemsStream(String userId) async* {
    try {
      final snapshot = await _supabase
          .from('pinned_items')
          .select()
          .eq('user_id', userId)
          .order('position', ascending: true);
      yield snapshot.map(PinnedItem.fromMap).toList();
    } catch (_) {
      yield [];
    }
  }

  @override
  Future<void> pinItem(PinnedItem item) async {
    // Upsert basato su (user_id, position) per permettere la sostituzione
    await _supabase
        .from('pinned_items')
        .upsert(item.toMap(), onConflict: 'user_id, position');
  }

  @override
  Future<void> unpinItem(String pinnedItemId) async {
    await _supabase.from('pinned_items').delete().eq('id', pinnedItemId);
  }

  // ── Diario Recente ─────────────────────────────────────────────────────────

  @override
  Stream<List<VaultEntry>> getRecentVaultStream(
    String userId, {
    int limit = 20,
  }) async* {
    try {
      final snapshot = await _supabase
          .from('vault_recent')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false)
          .limit(limit);
      yield snapshot.map(VaultEntry.fromMap).toList();
    } catch (_) {
      yield [];
    }
  }

  // ── Follow System ─────────────────────────────────────────────────────────

  @override
  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    final existing = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('follows').delete().eq('id', existing['id']);
      return false; // ora non segue più
    } else {
      await _supabase.from('follows').insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });
      return true; // ora segue
    }
  }

  @override
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final row = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<List<AppUser>> getFollowing(String userId) async {
    try {
      final rows = await _supabase
          .from('follows')
          .select(
            'profiles!following_id(id, email, display_name, photo_url, bio, is_public)',
          )
          .eq('follower_id', userId);

      return rows
          .map<AppUser>(
            (row) => _mapProfileToUser(
              Map<String, dynamic>.from(row['profiles'] ?? {}),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AppUser>> getFollowers(String userId) async {
    try {
      final rows = await _supabase
          .from('follows')
          .select(
            'profiles!follower_id(id, email, display_name, photo_url, bio, is_public)',
          )
          .eq('following_id', userId);

      return rows
          .map<AppUser>(
            (row) => _mapProfileToUser(
              Map<String, dynamic>.from(row['profiles'] ?? {}),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AppUser _mapProfileToUser(Map<String, dynamic> data) {
    return AppUser(
      id: data['id']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      displayName: data['display_name']?.toString(),
      photoUrl: data['photo_url']?.toString(),
      bio: data['bio']?.toString(),
      isPublic: data['is_public'] as bool? ?? true,
      languagePreference: data['language_preference']?.toString() ?? 'it-IT',
    );
  }
}
