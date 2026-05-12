import '../repositories/rating_repository.dart';

class SaveRatingUseCase {
  final RatingRepository repository;

  SaveRatingUseCase(this.repository);

  Future<void> call({
    required String userId,
    required int mediaId,
    required String mediaType,
    required int rating,
  }) async {
    return repository.saveRating(
      userId: userId,
      mediaId: mediaId,
      mediaType: mediaType,
      rating: rating,
    );
  }
}
