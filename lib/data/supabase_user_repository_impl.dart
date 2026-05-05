import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../services/utility_services/review_author_sync_service.dart';

class SupabaseUserRepositoryImpl implements UserRepository {
  final SupabaseClient _supabase;
  final ReviewAuthorSyncService _reviewAuthorSyncService;

  SupabaseUserRepositoryImpl({
    SupabaseClient? supabaseClient,
    ReviewAuthorSyncService? reviewAuthorSyncService,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _reviewAuthorSyncService =
           reviewAuthorSyncService ?? ReviewAuthorSyncService();

  @override
  Future<AppUser?> getUserData(String uid) async {
    final cacheBox = Hive.box('cinelib_cache');
    final cacheKey = 'profile_$uid';

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .single();

      final profile = Map<String, dynamic>.from(data);
      await cacheBox.put(cacheKey, profile);

      return _mapProfileToUser(profile);
    } catch (e) {
      print("Errore Supabase getUserData: $e");

      final cachedProfile = cacheBox.get(cacheKey);
      if (cachedProfile is Map) {
        return _mapProfileToUser(Map<String, dynamic>.from(cachedProfile));
      }

      return null;
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? bio,
    bool? isPublic,
    String? languagePreference,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['display_name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (isPublic != null) updates['is_public'] = isPublic;
    if (languagePreference != null) {
      updates['language_preference'] = languagePreference;
    }

    if (updates.isEmpty) return;

    try {
      await _supabase.from('profiles').update(updates).eq('id', uid);
      await _mergeCachedProfile(uid, updates);

      if (name != null) {
        final currentUser = _supabase.auth.currentUser;
        final currentMeta = Map<String, dynamic>.from(
          currentUser?.userMetadata ?? {},
        );
        currentMeta['display_name'] = name;
        currentMeta['name'] = name;

        await _supabase.auth.updateUser(UserAttributes(data: currentMeta));
        await _reviewAuthorSyncService.sync(userId: uid, author: name);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception("Questo nome e gia stato preso. Scegline un altro.");
      }
      throw Exception("Errore DB: ${e.message}");
    } catch (e) {
      throw Exception("Errore imprevisto durante il salvataggio: $e");
    }
  }

  @override
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    try {
      await _supabase
          .from('profiles')
          .update({'photo_url': avatarUrl})
          .eq('id', userId);
      await _mergeCachedProfile(userId, {'photo_url': avatarUrl});

      final currentUser = _supabase.auth.currentUser;
      final currentMeta = Map<String, dynamic>.from(
        currentUser?.userMetadata ?? {},
      );
      currentMeta['avatar_url'] = avatarUrl;

      await _supabase.auth.updateUser(UserAttributes(data: currentMeta));
      await _reviewAuthorSyncService.sync(userId: userId, avatarUrl: avatarUrl);
    } catch (e) {
      throw Exception('Errore durante il salvataggio dell\'avatar: $e');
    }
  }

  AppUser _mapProfileToUser(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'],
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? 'Utente',
      bio: data['bio'],
      isPublic: data['is_public'] ?? true,
      photoUrl: data['photo_url'],
      languagePreference: data['language_preference'] ?? 'it-IT',
    );
  }

  Future<void> _mergeCachedProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    final cacheBox = Hive.box('cinelib_cache');
    final cacheKey = 'profile_$uid';
    final cachedProfile = cacheBox.get(cacheKey);
    final mergedProfile = cachedProfile is Map
        ? Map<String, dynamic>.from(cachedProfile)
        : <String, dynamic>{'id': uid};

    mergedProfile.addAll(updates);
    await cacheBox.put(cacheKey, mergedProfile);
  }
}
