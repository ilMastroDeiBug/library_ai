import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/app_user.dart';

void main() {
  group('AppUser bulk constructor tests', () {
    test('default isPublic is true', () {
      final user = AppUser(id: '1', email: 'a@mail.com');
      expect(user.isPublic, isTrue);
      expect(user.displayName, isNull);
      expect(user.bio, isNull);
    });

    test('explicit isPublic false is preserved', () {
      final user = AppUser(
        id: '2',
        email: 'b@mail.com',
        displayName: 'B',
        bio: 'Bio',
        isPublic: false,
      );

      expect(user.isPublic, isFalse);
      expect(user.displayName, 'B');
      expect(user.bio, 'Bio');
    });

    for (var i = 0; i < 1000; i++) {
      test('constructor stress #$i', () {
        final user = AppUser(
          id: 'u$i',
          email: 'user$i@mail.com',
          displayName: i.isEven ? 'User $i' : null,
          bio: i % 3 == 0 ? 'Bio $i' : null,
          isPublic: i.isEven,
        );

        expect(user.id, 'u$i');
        expect(user.email, 'user$i@mail.com');
        expect(user.isPublic, i.isEven);
      });
    }
  });
}
