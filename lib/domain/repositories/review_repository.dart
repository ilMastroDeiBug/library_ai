import '../entities/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getMediaReviews(
    int mediaId,
    String mediaType,
    String currentUserId, {
    String sortBy = 'relevance',
  });
  Future<void> submitReview(
    int mediaId,
    String mediaType,
    String userId,
    String content,
    double rating,
  );
  Future<void> voteReview(String reviewId, String userId, int vote);
  Future<void> deleteReview(String reviewId, String userId);
}
