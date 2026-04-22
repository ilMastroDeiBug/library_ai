import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';

// 1. Creiamo un finto Repository che obbedisce ai nostri comandi
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late LoginWithEmailUseCase loginUseCase;
  late RegisterUseCase registerUseCase;
  late GoogleLoginUseCase googleLoginUseCase;
  late UpdateProfileUseCase updateProfileUseCase;
  late LogoutUseCase logoutUseCase;
  late ResetPasswordUseCase resetPasswordUseCase;
  late DeleteAccountUseCase deleteAccountUseCase;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    loginUseCase = LoginWithEmailUseCase(mockAuthRepo);
    registerUseCase = RegisterUseCase(mockAuthRepo);
    googleLoginUseCase = GoogleLoginUseCase(mockAuthRepo);
    updateProfileUseCase = UpdateProfileUseCase(mockAuthRepo);
    logoutUseCase = LogoutUseCase(mockAuthRepo);
    resetPasswordUseCase = ResetPasswordUseCase(mockAuthRepo);
    deleteAccountUseCase = DeleteAccountUseCase(mockAuthRepo);
  });

  group('Valanga di Test: Auth Use Cases', () {
    const tEmail = 'test@cineshare.com';
    const tPassword = 'Password123!';
    const tName = 'Bruce Wayne';

    // --- TEST LOGIN EMAIL ---
    test(
      '1. Login: deve chiamare signInWithEmail sul repository e avere successo',
      () async {
        when(
          () => mockAuthRepo.signInWithEmail(tEmail, tPassword),
        ).thenAnswer((_) async => Future.value());

        await loginUseCase.call(tEmail, tPassword);

        verify(() => mockAuthRepo.signInWithEmail(tEmail, tPassword)).called(1);
        verifyNoMoreInteractions(mockAuthRepo);
      },
    );

    test(
      '2. Login: deve lanciare un errore se il repository fallisce',
      () async {
        when(
          () => mockAuthRepo.signInWithEmail(tEmail, tPassword),
        ).thenThrow(Exception('Invalid login credentials'));

        expect(() => loginUseCase.call(tEmail, tPassword), throwsException);
      },
    );

    // --- TEST REGISTRAZIONE ---
    test(
      '3. Registrazione: deve chiamare register (NON signUpWithEmail)',
      () async {
        // FIX: Qui usiamo 'register' perché è così che lo hai chiamato nel tuo AuthRepository!
        when(
          () => mockAuthRepo.register(tEmail, tPassword),
        ).thenAnswer((_) async => Future.value());

        await registerUseCase.call(tEmail, tPassword);

        verify(() => mockAuthRepo.register(tEmail, tPassword)).called(1);
      },
    );

    // --- TEST GOOGLE LOGIN ---
    test('4. Google Login: deve chiamare signInWithGoogle', () async {
      when(
        () => mockAuthRepo.signInWithGoogle(),
      ).thenAnswer((_) async => Future.value());

      await googleLoginUseCase.call();

      verify(() => mockAuthRepo.signInWithGoogle()).called(1);
    });

    // --- TEST UPDATE PROFILE ---
    test('5. Aggiorna Profilo: deve chiamare updateDisplayName', () async {
      when(
        () => mockAuthRepo.updateDisplayName(tName),
      ).thenAnswer((_) async => Future.value());

      await updateProfileUseCase.call(tName);

      verify(() => mockAuthRepo.updateDisplayName(tName)).called(1);
    });

    // --- TEST LOGOUT ---
    test('6. Logout: deve chiamare logout sul repository', () async {
      when(() => mockAuthRepo.logout()).thenAnswer((_) async => Future.value());

      await logoutUseCase.call();

      verify(() => mockAuthRepo.logout()).called(1);
    });

    // --- TEST RESET PASSWORD ---
    test('7. Reset Password: deve chiamare sendPasswordReset', () async {
      when(
        () => mockAuthRepo.sendPasswordReset(tEmail),
      ).thenAnswer((_) async => Future.value());

      await resetPasswordUseCase.call(tEmail);

      verify(() => mockAuthRepo.sendPasswordReset(tEmail)).called(1);
    });

    // --- TEST DELETE ACCOUNT ---
    test('8. Elimina Account: deve chiamare deleteAccount', () async {
      when(
        () => mockAuthRepo.deleteAccount(),
      ).thenAnswer((_) async => Future.value());

      await deleteAccountUseCase.call();

      verify(() => mockAuthRepo.deleteAccount()).called(1);
    });
  });
}
