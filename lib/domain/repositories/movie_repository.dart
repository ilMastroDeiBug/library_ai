import '../entities/movie.dart'; // O models/.../movie_model.dart
import '../../models/movie_widget/review_model.dart';
import '../../models/movie_widget/cast_model.dart';

abstract class MovieRepository {
  // DB
  Stream<List<Movie>> getWatchlistStream(String userId, String status);
  Future<void> saveMovie(Movie movie, String userId);
  Future<void> updateMovieStatus(int movieId, String newStatus);
  Future<void> deleteMovie(int movieId);
  Future<void> saveAnalysis(int movieId, String analysis);

  // API (TMDB)
  Future<List<Movie>> getMoviesByCategory(String categoryPath);
  Future<List<Review>> getMovieReviews(int movieId);
  Future<List<CastMember>> getMovieCast(int movieId);
}
