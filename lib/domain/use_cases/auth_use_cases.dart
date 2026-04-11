import '../repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository repository;
  LoginWithEmailUseCase(this.repository);
  Future<void> call(String email, String password) =>
      repository.signInWithEmail(email, password);
}

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);
  Future<void> call(String email, String password) =>
      repository.register(email, password);
}

class GoogleLoginUseCase {
  final AuthRepository repository;
  GoogleLoginUseCase(this.repository);
  Future<void> call() => repository.signInWithGoogle();
}

class UpdateProfileUseCase {
  final AuthRepository repository;
  UpdateProfileUseCase(this.repository);
  Future<void> call(String name) => repository.updateDisplayName(name);
}

class LogoutUseCase {
  final AuthRepository repository;
  LogoutUseCase(this.repository);
  Future<void> call() => repository.logout();
}

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> call(String email) => repository.sendPasswordReset(email);
}

class DeleteAccountUseCase {
  final AuthRepository repository;
  DeleteAccountUseCase(this.repository);

  Future<void> call() => repository.deleteAccount();
}
