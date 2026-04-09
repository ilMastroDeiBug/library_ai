import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get userStream;

  // FIX ARCHITETTURALE: Usa AppUser, NON l'User di Firebase!
  AppUser? get currentUser;

  Future<void> signInWithEmail(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> logout();
  Future<void> updateDisplayName(String name);
  Future<void> sendPasswordReset(String email);
}
