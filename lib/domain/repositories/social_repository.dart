import '../entities/pinned_item.dart';
import '../entities/vault_entry.dart';
import '../entities/social_stats.dart';
import '../entities/app_user.dart';

/// Contratto del repository per tutte le funzionalità del profilo social.
/// Seguendo DDD, questa interfaccia vive nel dominio ed è ignara
/// dell'implementazione concreta (Supabase).
abstract class SocialRepository {
  // ── Statistiche ────────────────────────────────────────────────────────────

  /// Restituisce i contatori aggregati (follower, seguiti, vault) per [userId].
  Future<SocialStats> getSocialStats(String userId);

  // ── Vetrina (Pinned Items) ─────────────────────────────────────────────────

  /// Lista delle 4 opere pinnate dall'utente.
  Stream<List<PinnedItem>> getPinnedItemsStream(String userId);

  /// Fissa un'opera in posizione [position] (0..3).
  /// Se la posizione è già occupata, la sovrascrive.
  Future<void> pinItem(PinnedItem item);

  /// Rimuove un'opera pinnata per id.
  Future<void> unpinItem(String pinnedItemId);

  // ── Diario Recente (Vault Entries) ────────────────────────────────────────

  /// Stream delle ultime [limit] opere aggiunte al vault dell'utente.
  Stream<List<VaultEntry>> getRecentVaultStream(String userId, {int limit = 20});

  // ── Follow System ─────────────────────────────────────────────────────────

  /// Segue o smette di seguire [targetUserId]. Restituisce il nuovo stato.
  Future<bool> toggleFollow(String currentUserId, String targetUserId);

  /// `true` se [currentUserId] segue già [targetUserId].
  Future<bool> isFollowing(String currentUserId, String targetUserId);

  /// Lista degli utenti che [userId] segue.
  Future<List<AppUser>> getFollowing(String userId);

  /// Lista degli utenti che seguono [userId].
  Future<List<AppUser>> getFollowers(String userId);
}
