import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/repositories/user_repository.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository userRepository;
  late GetUserDataUseCase getUserDataUseCase;
  late UpdateBioUseCase updateBioUseCase;
  late UpdatePrivacyUseCase updatePrivacyUseCase;

  setUp(() {
    userRepository = MockUserRepository();
    getUserDataUseCase = GetUserDataUseCase(userRepository);
    updateBioUseCase = UpdateBioUseCase(userRepository);
    updatePrivacyUseCase = UpdatePrivacyUseCase(userRepository);
  });

  group('User use cases advanced tests', () {
    for (var i = 0; i < 200; i++) {
      test('GetUserData returns mapped user from repository #$i', () async {
        final uid = 'uid_$i';
        final user = AppUser(
          id: uid,
          email: 'user$i@mail.com',
          displayName: 'User $i',
          bio: i.isEven ? 'Bio $i' : null,
          isPublic: i.isEven,
        );

        when(
          () => userRepository.getUserData(uid),
        ).thenAnswer((_) async => user);

        final result = await getUserDataUseCase.call(uid);

        expect(result, isNotNull);
        expect(result!.id, uid);
        expect(result.isPublic, i.isEven);
        verify(() => userRepository.getUserData(uid)).called(1);
      });
    }

    for (var i = 0; i < 300; i++) {
      test('UpdateBio forwards uid and bio #$i', () async {
        final uid = 'uid_$i';
        final bio = 'Updated bio #$i';

        when(
          () => userRepository.updateProfile(uid: uid, bio: bio),
        ).thenAnswer((_) async {});

        await updateBioUseCase.call(uid, bio);

        verify(
          () => userRepository.updateProfile(uid: uid, bio: bio),
        ).called(1);
      });
    }

    for (var i = 0; i < 300; i++) {
      test('UpdatePrivacy forwards uid and isPublic #$i', () async {
        final uid = 'uid_$i';
        final isPublic = i % 3 == 0;

        when(
          () => userRepository.updateProfile(uid: uid, isPublic: isPublic),
        ).thenAnswer((_) async {});

        await updatePrivacyUseCase.call(uid, isPublic);

        verify(
          () => userRepository.updateProfile(uid: uid, isPublic: isPublic),
        ).called(1);
      });
    }

    test('GetUserData propagates repository exception', () async {
      when(
        () => userRepository.getUserData('uid_fail'),
      ).thenThrow(Exception('get user failed'));

      expect(() => getUserDataUseCase.call('uid_fail'), throwsException);
    });

    test('UpdateBio propagates repository exception', () async {
      when(
        () => userRepository.updateProfile(uid: 'u', bio: 'b'),
      ).thenThrow(Exception('update bio failed'));

      expect(() => updateBioUseCase.call('u', 'b'), throwsException);
    });

    test('UpdatePrivacy propagates repository exception', () async {
      when(
        () => userRepository.updateProfile(uid: 'u', isPublic: false),
      ).thenThrow(Exception('update privacy failed'));

      expect(() => updatePrivacyUseCase.call('u', false), throwsException);
    });
  });
}
