import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late LoginWithEmailUseCase loginUseCase;
  late RegisterUseCase registerUseCase;
  late GoogleLoginUseCase googleLoginUseCase;
  late UpdateProfileUseCase updateProfileUseCase;
  late LogoutUseCase logoutUseCase;
  late ResetPasswordUseCase resetPasswordUseCase;
  late DeleteAccountUseCase deleteAccountUseCase;

  setUp(() {
    authRepository = MockAuthRepository();
    loginUseCase = LoginWithEmailUseCase(authRepository);
    registerUseCase = RegisterUseCase(authRepository);
    googleLoginUseCase = GoogleLoginUseCase(authRepository);
    updateProfileUseCase = UpdateProfileUseCase(authRepository);
    logoutUseCase = LogoutUseCase(authRepository);
    resetPasswordUseCase = ResetPasswordUseCase(authRepository);
    deleteAccountUseCase = DeleteAccountUseCase(authRepository);
  });

  group('Auth use cases advanced bulk tests', () {
    for (var i = 0; i < 200; i++) {
      test('Login forwarding matrix #$i', () async {
        final email = 'user$i@mail.com';
        final password = 'Pass!$i';

        when(
          () => authRepository.signInWithEmail(email, password),
        ).thenAnswer((_) async {});

        await loginUseCase.call(email, password);

        verify(() => authRepository.signInWithEmail(email, password)).called(1);
      });
    }

    for (var i = 0; i < 200; i++) {
      test('Register forwarding matrix #$i', () async {
        final email = 'new$i@mail.com';
        final password = 'Reg!$i';

        when(
          () => authRepository.register(email, password),
        ).thenAnswer((_) async {});

        await registerUseCase.call(email, password);

        verify(() => authRepository.register(email, password)).called(1);
      });
    }

    for (var i = 0; i < 120; i++) {
      test('Reset password forwarding matrix #$i', () async {
        final email = 'reset$i@mail.com';

        when(
          () => authRepository.sendPasswordReset(email),
        ).thenAnswer((_) async {});

        await resetPasswordUseCase.call(email);

        verify(() => authRepository.sendPasswordReset(email)).called(1);
      });
    }

    for (var i = 0; i < 120; i++) {
      test('Update display name forwarding matrix #$i', () async {
        final name = 'User Name $i';

        when(
          () => authRepository.updateDisplayName(name),
        ).thenAnswer((_) async {});

        await updateProfileUseCase.call(name);

        verify(() => authRepository.updateDisplayName(name)).called(1);
      });
    }

    for (var i = 0; i < 80; i++) {
      test('Google login forwarding matrix #$i', () async {
        when(() => authRepository.signInWithGoogle()).thenAnswer((_) async {});

        await googleLoginUseCase.call();

        verify(() => authRepository.signInWithGoogle()).called(1);
      });
    }

    for (var i = 0; i < 80; i++) {
      test('Logout forwarding matrix #$i', () async {
        when(() => authRepository.logout()).thenAnswer((_) async {});

        await logoutUseCase.call();

        verify(() => authRepository.logout()).called(1);
      });
    }

    for (var i = 0; i < 80; i++) {
      test('Delete account forwarding matrix #$i', () async {
        when(() => authRepository.deleteAccount()).thenAnswer((_) async {});

        await deleteAccountUseCase.call();

        verify(() => authRepository.deleteAccount()).called(1);
      });
    }

    test('Login propagates repository error', () async {
      when(
        () => authRepository.signInWithEmail('x@mail.com', 'x'),
      ).thenThrow(Exception('auth error'));

      expect(() => loginUseCase.call('x@mail.com', 'x'), throwsException);
    });

    test('Register propagates repository error', () async {
      when(
        () => authRepository.register('x@mail.com', 'x'),
      ).thenThrow(Exception('register error'));

      expect(() => registerUseCase.call('x@mail.com', 'x'), throwsException);
    });

    test('Google login propagates repository error', () async {
      when(
        () => authRepository.signInWithGoogle(),
      ).thenThrow(Exception('google error'));

      expect(() => googleLoginUseCase.call(), throwsException);
    });

    test('Update profile propagates repository error', () async {
      when(
        () => authRepository.updateDisplayName('name'),
      ).thenThrow(Exception('update error'));

      expect(() => updateProfileUseCase.call('name'), throwsException);
    });

    test('Logout propagates repository error', () async {
      when(() => authRepository.logout()).thenThrow(Exception('logout error'));

      expect(() => logoutUseCase.call(), throwsException);
    });

    test('Reset password propagates repository error', () async {
      when(
        () => authRepository.sendPasswordReset('x@mail.com'),
      ).thenThrow(Exception('reset error'));

      expect(() => resetPasswordUseCase.call('x@mail.com'), throwsException);
    });

    test('Delete account propagates repository error', () async {
      when(
        () => authRepository.deleteAccount(),
      ).thenThrow(Exception('delete error'));

      expect(() => deleteAccountUseCase.call(), throwsException);
    });
  });
}
