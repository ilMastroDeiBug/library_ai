import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/rating_repository.dart';

class SupabaseRatingRepositoryImpl implements RatingRepository {
  final SupabaseClient supabase;

  SupabaseRatingRepositoryImpl({required this.supabase});

  @override
  Future<void> saveRating({
    required String userId,
    required int mediaId,
    required String mediaType,
    required int rating,
  }) async {
    try {
      await supabase.from('media_ratings').upsert({
        'user_id': userId,
        'media_id': mediaId,
        'media_type': mediaType,
        'rating': rating,
      }, onConflict: 'user_id, media_id, media_type');
    } catch (e) {
      print('DEBUG RATING ERROR: $e');
      throw Exception('Failed to save rating: $e');
    }
  }
}
