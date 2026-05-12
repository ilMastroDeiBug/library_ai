abstract class RatingRepository {
  Future<void> saveRating({
    required String userId,
    required int mediaId,
    required String mediaType,
    required int rating,
  });
}
