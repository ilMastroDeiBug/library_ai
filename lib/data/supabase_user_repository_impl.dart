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
        id: data['id'], // <-- CORRETTO
        email: data['email'] ?? '',
        displayName: data['display_name'] ?? 'Utente',
        bio: data['bio'], // <-- AGGIUNTO
        isPublic: data['is_public'] ?? true, // <-- AGGIUNTO
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
}
