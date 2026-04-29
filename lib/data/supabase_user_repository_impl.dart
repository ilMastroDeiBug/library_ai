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
        photoUrl: data['photo_url'],
        languagePreference: data['language_preference'] ?? 'it-IT',
      );
    } catch (e) {
      print("Errore Supabase getUserData: $e");
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

    if (updates.isNotEmpty) {
      try {
        // 1. Aggiorna la tabella (gestito il vincolo di univocità)
        await _supabase.from('profiles').update(updates).eq('id', uid);

        // 2. MERGE SICURO DEI METADATI (Non distrugge l'avatar)
        if (name != null) {
          final currentUser = _supabase.auth.currentUser;
          // Creiamo una copia esatta dei metadati attuali
          final currentMeta = Map<String, dynamic>.from(
            currentUser?.userMetadata ?? {},
          );
          // Aggiorniamo solo il nome
          currentMeta['display_name'] = name;

          await _supabase.auth.updateUser(UserAttributes(data: currentMeta));
        }
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw Exception("Questo nome è già stato preso. Scegline un altro.");
        }
        throw Exception("Errore DB: ${e.message}");
      } catch (e) {
        throw Exception("Errore imprevisto durante il salvataggio: $e");
      }
    }
  }

  @override
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    try {
      // 1. Aggiorna la tabella profiles
      await _supabase
          .from('profiles')
          .update({'photo_url': avatarUrl})
          .eq('id', userId);

      // 2. MERGE SICURO DEI METADATI (Non distrugge il nome)
      final currentUser = _supabase.auth.currentUser;
      // Creiamo una copia esatta dei metadati attuali
      final currentMeta = Map<String, dynamic>.from(
        currentUser?.userMetadata ?? {},
      );
      // Aggiorniamo solo l'avatar
      currentMeta['avatar_url'] = avatarUrl;

      await _supabase.auth.updateUser(UserAttributes(data: currentMeta));
    } catch (e) {
      throw Exception('Errore durante il salvataggio dell\'avatar: $e');
    }
  }
}
