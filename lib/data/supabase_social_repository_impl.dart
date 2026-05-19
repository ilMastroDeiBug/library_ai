import 'package:supabase_flutter/supabase_flutter.dart';
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
    try {
      final followersRes = await _supabase
          .from('follows')
          .select()
          .eq('following_id', userId)
          .count(CountOption.exact);

      final followingRes = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .count(CountOption.exact);

      final moviesRes = await _supabase
          .from('user_watchlist')
          .select()
          .eq('user_id', userId)
          .eq('type', 'movie')
          .count(CountOption.exact);

      final tvRes = await _supabase
          .from('user_watchlist')
          .select()
          .eq('user_id', userId)
          .eq('type', 'tv')
          .count(CountOption.exact);

      final booksRes = await _supabase
          .from('user_books')
          .select()
          .eq('user_id', userId)
          .count(CountOption.exact);

      return SocialStats(
        followersCount: followersRes.count ?? 0,
        followingCount: followingRes.count ?? 0,
        moviesCount: moviesRes.count ?? 0,
        tvCount: tvRes.count ?? 0,
        booksCount: booksRes.count ?? 0,
      );
    } catch (_) {
      return const SocialStats();

    }
  }

  // ── Vetrina (Pinned Items) ─────────────────────────────────────────────────

  @override
  Stream<List<PinnedItem>> getPinnedItemsStream(String userId) {
    return _supabase
        .from('pinned_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('position', ascending: true)
        .map((rows) => rows.map(PinnedItem.fromMap).toList());
  }

  @override
  Future<void> pinItem(PinnedItem item) async {
    // Upsert basato su (user_id, position) per permettere la sostituzione
    await _supabase.from('pinned_items').upsert(
      item.toMap(),
      onConflict: 'user_id, position',
    );
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
  }) {
    // Usiamo la vista `vault_recent` che aggrega film e serie in ordine cronologico.
    // La vista deve essere creata su Supabase (vedi istruzioni SQL allegate).
    return _supabase
        .from('vault_recent')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('added_at', ascending: false)
        .limit(limit)
        .map((rows) => rows.map(VaultEntry.fromMap).toList());
  }

  // ── Follow System ─────────────────────────────────────────────────────────

  @override
  Future<bool> toggleFollow(
    String currentUserId,
    String targetUserId,
  ) async {
    final existing = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('follows')
          .delete()
          .eq('id', existing['id']);
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
          .select('profiles!following_id(*)')
          .eq('follower_id', userId);

      return rows
          .map<AppUser>((row) => _mapProfileToUser(
                Map<String, dynamic>.from(row['profiles'] ?? {}),
              ))
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
          .select('profiles!follower_id(*)')
          .eq('following_id', userId);

      return rows
          .map<AppUser>((row) => _mapProfileToUser(
                Map<String, dynamic>.from(row['profiles'] ?? {}),
              ))
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
