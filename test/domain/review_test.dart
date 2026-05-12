import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/review.dart';

void main() {
  group('Review Entity', () {
    test('relevanceScore calculates correctly', () {
      final review = Review(
        id: '1',
        author: 'A',
        content: 'C',
        rating: 5.0,
        isCustom: true,
        likes: 10,
        dislikes: 2,
      );

      expect(review.relevanceScore, 8);
    });

    test('relevanceScore can be negative', () {
      final review = Review(
        id: '1',
        author: 'A',
        content: 'C',
        rating: 5.0,
        isCustom: true,
        likes: 2,
        dislikes: 10,
      );

      expect(review.relevanceScore, -8);
    });

    test('isWrittenBy correctly identifies ownership', () {
      final review = Review(
        id: '1',
        userId: 'user123',
        author: 'A',
        content: 'C',
        rating: 5.0,
        isCustom: true,
      );

      expect(review.isWrittenBy('user123'), isTrue);
      expect(review.isWrittenBy('otherUser'), isFalse);
      expect(review.isWrittenBy(null), isFalse);
    });

    test('isWrittenBy returns false if not custom', () {
      final review = Review(
        id: '1',
        userId: 'user123',
        author: 'A',
        content: 'C',
        rating: 5.0,
        isCustom: false,
      );

      expect(review.isWrittenBy('user123'), isFalse);
    });

    test('copyWith updates fields correctly', () {
      final review = Review(
        id: '1',
        userId: 'user123',
        author: 'A',
        content: 'C',
        rating: 5.0,
        isCustom: true,
        likes: 5,
        dislikes: 1,
        userVote: 0,
      );

      final updated = review.copyWith(likes: 6, userVote: 1);

      expect(updated.id, '1');
      expect(updated.likes, 6);
      expect(updated.dislikes, 1);
      expect(updated.userVote, 1);
      expect(updated.author, 'A');
      expect(updated.content, 'C');
      expect(updated.isCustom, isTrue);
    });

    test('copyWith keeps original values if not specified', () {
      final review = Review(
        id: '1',
        author: 'A',
        content: 'C',
        rating: 4.0,
        isCustom: false,
        likes: 0,
        dislikes: 0,
        userVote: 0,
      );

      final updated = review.copyWith();

      expect(updated.likes, 0);
      expect(updated.dislikes, 0);
      expect(updated.userVote, 0);
    });
  });
}
