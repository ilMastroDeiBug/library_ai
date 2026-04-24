import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/app_user.dart';

class SupabaseUserRepositoryImpl implements UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<AppUser?> getUserData(String uid) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .single();

      return AppUser(
        id: data['id'],
        email: data['email'] ?? '',
        displayName: data['display_name'] ?? 'Utente',
        bio: data['bio'],
        isPublic: data['is_public'] ?? true,
        photoUrl: data['photo_url'], // <-- Estrazione dell'avatar aggiunta
      );
    } catch (e) {
      print("Errore Supabase getUserData: $e");
      return null;
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? bio,
    bool? isPublic,
  }) async {
    final updates = <String, dynamic>{};

    if (bio != null) updates['bio'] = bio;
    if (isPublic != null) updates['is_public'] = isPublic;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', uid);
    }
  }

  @override
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    try {
      // 1. Aggiorna la tabella profiles (coerente con getUserData)
      await _supabase
          .from('profiles')
          .update({'photo_url': avatarUrl})
          .eq('id', userId);

      // 2. Aggiorna i metadati di autenticazione usando la sintassi corretta
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': avatarUrl}),
      );
    } catch (e) {
      throw Exception('Errore durante il salvataggio dell\'avatar: $e');
    }
  }
}
