import '../repositories/social_repository.dart';
import '../entities/pinned_item.dart';
import '../entities/vault_entry.dart';
import '../entities/social_stats.dart';
import '../entities/app_user.dart';

// ── Stats ────────────────────────────────────────────────────────────────────

class GetSocialStatsUseCase {
  final SocialRepository _repository;
  GetSocialStatsUseCase(this._repository);
  Future<SocialStats> call(String userId) => _repository.getSocialStats(userId);
}

// ── Pinned Items ──────────────────────────────────────────────────────────────

class GetPinnedItemsUseCase {
  final SocialRepository _repository;
  GetPinnedItemsUseCase(this._repository);
  Stream<List<PinnedItem>> call(String userId) =>
      _repository.getPinnedItemsStream(userId);
}

class PinItemUseCase {
  final SocialRepository _repository;
  PinItemUseCase(this._repository);
  Future<void> call(PinnedItem item) => _repository.pinItem(item);
}

class UnpinItemUseCase {
  final SocialRepository _repository;
  UnpinItemUseCase(this._repository);
  Future<void> call(String pinnedItemId) => _repository.unpinItem(pinnedItemId);
}

// ── Vault (Diario recente) ────────────────────────────────────────────────────

class GetRecentVaultUseCase {
  final SocialRepository _repository;
  GetRecentVaultUseCase(this._repository);
  Stream<List<VaultEntry>> call(String userId, {int limit = 20}) =>
      _repository.getRecentVaultStream(userId, limit: limit);
}

// ── Follow System ─────────────────────────────────────────────────────────────

class ToggleFollowUseCase {
  final SocialRepository _repository;
  ToggleFollowUseCase(this._repository);
  /// Ritorna `true` se dopo l'operazione l'utente sta seguendo il target.
  Future<bool> call(String currentUserId, String targetUserId) =>
      _repository.toggleFollow(currentUserId, targetUserId);
}

class IsFollowingUseCase {
  final SocialRepository _repository;
  IsFollowingUseCase(this._repository);
  Future<bool> call(String currentUserId, String targetUserId) =>
      _repository.isFollowing(currentUserId, targetUserId);
}

class GetFollowingUseCase {
  final SocialRepository _repository;
  GetFollowingUseCase(this._repository);
  Future<List<AppUser>> call(String userId) => _repository.getFollowing(userId);
}

class GetFollowersUseCase {
  final SocialRepository _repository;
  GetFollowersUseCase(this._repository);
  Future<List<AppUser>> call(String userId) => _repository.getFollowers(userId);
}
