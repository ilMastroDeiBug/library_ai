import '../repositories/review_repository.dart';
import '../entities/review.dart';

class GetMediaReviewsUseCase {
  final ReviewRepository repository;
  GetMediaReviewsUseCase(this.repository);

  Future<List<Review>> call(
    int mediaId,
    String mediaType,
    String currentUserId, {
    String sortBy = 'relevance',
  }) {
    return repository.getMediaReviews(
      mediaId,
      mediaType,
      currentUserId,
      sortBy: sortBy,
    );
  }
}

class SubmitReviewUseCase {
  final ReviewRepository repository;
  SubmitReviewUseCase(this.repository);

  Future<void> call(
    int mediaId,
    String mediaType,
    String userId,
    String content,
    double rating,
  ) {
    return repository.submitReview(mediaId, mediaType, userId, content, rating);
  }
}

class VoteReviewUseCase {
  final ReviewRepository repository;
  VoteReviewUseCase(this.repository);

  Future<void> call(String reviewId, String userId, int vote) {
    return repository.voteReview(reviewId, userId, vote);
  }
}

class DeleteReviewUseCase {
  final ReviewRepository repository;
  DeleteReviewUseCase(this.repository);

  Future<void> call(String reviewId, String userId) {
    return repository.deleteReview(reviewId, userId);
  }
}
