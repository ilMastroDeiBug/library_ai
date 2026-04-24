import '../repositories/user_repository.dart'; // Devi aver creato questo repo (vedi step Libri/User)
import '../entities/app_user.dart';

class GetUserDataUseCase {
  final UserRepository repository;
  GetUserDataUseCase(this.repository);
  Future<AppUser?> call(String uid) => repository.getUserData(uid);
}

class UpdateBioUseCase {
  final UserRepository repository;
  UpdateBioUseCase(this.repository);
  Future<void> call(String uid, String bio) =>
      repository.updateProfile(uid: uid, bio: bio);
}

class UpdatePrivacyUseCase {
  final UserRepository repository;
  UpdatePrivacyUseCase(this.repository);
  Future<void> call(String uid, bool isPublic) =>
      repository.updateProfile(uid: uid, isPublic: isPublic);
}

class UpdateLanguagePreferenceUseCase {
  final UserRepository repository;
  UpdateLanguagePreferenceUseCase(this.repository);

  Future<void> call(String uid, String languagePreference) =>
      repository.updateProfile(
        uid: uid,
        languagePreference: languagePreference,
      );
}

class UpdateAvatarUseCase {
  final UserRepository repository;

  UpdateAvatarUseCase(this.repository);

  Future<void> call(String userId, String avatarUrl) async {
    return await repository.updateAvatar(userId, avatarUrl);
  }
}
