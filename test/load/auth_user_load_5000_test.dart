/*import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/repositories/user_repository.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';

class InMemoryAuthRepository implements AuthRepository {
  final List<String> loginCalls = [];
  final List<String> registerCalls = [];
  int googleCalls = 0;
  int logoutCalls = 0;
  int deleteCalls = 0;
  final List<String> resetCalls = [];
  final List<String> displayNameCalls = [];

  @override
  AppUser? currentUser;

  @override
  Stream<AppUser?> get userStream async* {
    yield currentUser;
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<void> register(String email, String password) async {
    registerCalls.add('$email|$password');
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resetCalls.add(email);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    loginCalls.add('$email|$password');
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    displayNameCalls.add(name);
  }
}

class InMemoryUserRepository implements UserRepository {
  final Map<String, AppUser> users = {};
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<AppUser?> getUserData(String uid) async => users[uid];

  @override
  Future<void> updateProfile({
    required String uid,
    String? bio,
    bool? isPublic,
    String? photoUrl,
  }) async {
    updateCalls.add({'uid': uid, 'bio': bio, 'isPublic': isPublic, 'photoUrl':  photoUrl});

    final current = users[uid] ?? AppUser(id: uid, email: '$uid@mail.com');
    users[uid] = AppUser(
      id: current.id,
      email: current.email,
      displayName: current.displayName,
      bio: bio ?? current.bio,
      isPublic: isPublic ?? current.isPublic,
      photoUrl: photoUrl ?? current.photoUrl,
    );
  }
}

void main() {
  group('Load simulation: 5000 users auth + profile updates', () {
    test('can process 5000 users through use-case layer', () async {
      const totalUsers = 5000;

      final authRepo = InMemoryAuthRepository();
      final userRepo = InMemoryUserRepository();

      final registerUseCase = RegisterUseCase(authRepo);
      final loginUseCase = LoginWithEmailUseCase(authRepo);
      final updateBioUseCase = UpdateBioUseCase(userRepo);
      final updatePrivacyUseCase = UpdatePrivacyUseCase(userRepo);
      final getUserDataUseCase = GetUserDataUseCase(userRepo);
      final updateAvatarUseCase = UpdateAvatarUseCase(userRepo);});

      for (var i = 0; i < totalUsers; i++) {
        final email = 'user_$i@mail.com';
        final password = 'Pass_$i!';
        final uid = 'uid_$i';

        await registerUseCase.call(email, password);
        await loginUseCase.call(email, password);
        await updateBioUseCase.call(uid, 'Bio for user $i');
        await updatePrivacyUseCase.call(uid, i.isEven);
        await updateAvatarUseCase.call(uid, 'photo for user $i');
      }

      expect(authRepo.registerCalls.length, totalUsers);
      expect(authRepo.loginCalls.length, totalUsers);
      expect(userRepo.updateCalls.length, totalUsers * 2);

      final sampleA = await getUserDataUseCase.call('uid_0');
      final sampleB = await getUserDataUseCase.call('uid_4999');

      expect(sampleA, isNotNull);
      expect(sampleA!.bio, 'Bio for user 0');
      expect(sampleA.isPublic, true);
      

      expect(sampleB, isNotNull);
      expect(sampleB!.bio, 'Bio for user 4999');
      expect(sampleB.isPublic, false);
    });
  });
}*/
