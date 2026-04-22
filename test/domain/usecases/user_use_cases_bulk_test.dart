import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/repositories/user_repository.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository repository;
  late GetUserDataUseCase getUserDataUseCase;
  late UpdateBioUseCase updateBioUseCase;
  late UpdatePrivacyUseCase updatePrivacyUseCase;

  setUp(() {
    repository = MockUserRepository();
    getUserDataUseCase = GetUserDataUseCase(repository);
    updateBioUseCase = UpdateBioUseCase(repository);
    updatePrivacyUseCase = UpdatePrivacyUseCase(repository);
  });

  group('User use cases bulk tests', () {
    test('GetUserDataUseCase forwards and returns user', () async {
      final user = AppUser(
        id: 'u1',
        email: 'u1@mail.com',
        displayName: 'User One',
        bio: 'Bio',
      );
      when(() => repository.getUserData('u1')).thenAnswer((_) async => user);

      final result = await getUserDataUseCase.call('u1');

      expect(result?.id, 'u1');
      verify(() => repository.getUserData('u1')).called(1);
    });

    test('GetUserDataUseCase can return null', () async {
      when(
        () => repository.getUserData('unknown'),
      ).thenAnswer((_) async => null);

      final result = await getUserDataUseCase.call('unknown');

      expect(result, isNull);
      verify(() => repository.getUserData('unknown')).called(1);
    });

    for (var i = 0; i < 500; i++) {
      test('UpdateBioUseCase forwards uid and bio #$i', () async {
        when(
          () => repository.updateProfile(uid: 'u$i', bio: 'bio_$i'),
        ).thenAnswer((_) async {});

        await updateBioUseCase.call('u$i', 'bio_$i');

        verify(
          () => repository.updateProfile(uid: 'u$i', bio: 'bio_$i'),
        ).called(1);
      });
    }

    for (var i = 0; i < 500; i++) {
      test('UpdatePrivacyUseCase forwards uid and privacy #$i', () async {
        final isPublic = i.isEven;
        when(
          () => repository.updateProfile(uid: 'u$i', isPublic: isPublic),
        ).thenAnswer((_) async {});

        await updatePrivacyUseCase.call('u$i', isPublic);

        verify(
          () => repository.updateProfile(uid: 'u$i', isPublic: isPublic),
        ).called(1);
      });
    }
  });
}
