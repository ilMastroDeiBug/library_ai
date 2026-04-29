import '../entities/app_user.dart';

abstract class UserRepository {
  // Scarica i dati completi di un utente
  Future<AppUser?> getUserData(String uid);

  // Aggiorna campi specifici (bio, privacy, ecc.)
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? bio,
    bool? isPublic,
    String? languagePreference,
  });
  Future<void> updateAvatar(String userId, String avatarUrl);
}
