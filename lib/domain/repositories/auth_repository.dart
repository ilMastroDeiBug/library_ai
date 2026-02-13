import '/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get userStream;
  Future<void> signInWithEmail(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> logout();
  Future<void> updateDisplayName(String name);
  Future<void> sendPasswordReset(String email);
}
