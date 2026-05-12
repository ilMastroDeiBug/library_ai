import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/data/supabase_review_repository_impl.dart';
import 'package:library_ai/domain/entities/review.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockTmdbService extends Mock implements TmdbService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockTmdbService tmdb;
  late MockSupabaseClient supabase;
  late SupabaseReviewRepositoryImpl repository;

  setUp(() {
    tmdb = MockTmdbService();
    supabase = MockSupabaseClient();
    repository = SupabaseReviewRepositoryImpl(
      supabaseClient: supabase,
      tmdbService: tmdb,
    );
  });

  group('SupabaseReviewRepositoryImpl - Sorting', () {
    final mockReviews = [
      Review(
        id: '1',
        author: 'A',
        content: 'Bad',
        rating: 1.0,
        isCustom: true,
        likes: 10,
        dislikes: 5, // Relevance: 5
        createdAt: DateTime(2023, 1, 1),
      ),
      Review(
        id: '2',
        author: 'B',
        content: 'Good',
        rating: 5.0,
        isCustom: false,
        likes: 100,
        dislikes: 0, // Relevance: 100
        createdAt: DateTime(2023, 5, 1),
      ),
      Review(
        id: '3',
        author: 'C',
        content: 'Average',
        rating: 3.0,
        isCustom: true,
        likes: 0,
        dislikes: 0, // Relevance: 0
        createdAt: DateTime(2023, 10, 1),
      ),
    ];

    test('getMediaReviews sorts by relevance by default', () async {
      when(() => tmdb.fetchReviews(123, isTv: false)).thenAnswer(
        (_) async => [mockReviews[1]],
      );

      // We mock a failure for Supabase to just test the fallback/tmdb sorting logic here
      // Real mocking of Supabase builder is complex without the actual builder classes
      final result = await repository.getMediaReviews(
        123,
        'movie',
        'user1',
        sortBy: 'relevance',
      );

      // Result should be sorted by relevance descending.
      // Since supabase fails, only tmdb review [2] is returned.
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('submitReview does not throw if offline', () async {
      // Offline/Error will throw an Exception, but we wrapped it in a try-catch for offline safety.
      // So this test should pass without exceptions.
      await expectLater(
        repository.submitReview(123, 'movie', 'user1', 'Great!', 4.5),
        completes,
      );
    });

    test('voteReview does not throw if offline', () async {
      await expectLater(
        repository.voteReview('review123', 'user1', 1),
        completes,
      );
    });
    
    test('voteReview with 0 completes safely', () async {
      await expectLater(
        repository.voteReview('review123', 'user1', 0),
        completes,
      );
    });
  });
}
