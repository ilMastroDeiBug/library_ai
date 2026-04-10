import '../entities/movie.dart';
import '../entities/tv_series.dart';
import '../../models/movie_widget/review_model.dart';
import '../../models/movie_widget/cast_model.dart';
import '../../models/movie_widget/watch_provider_model.dart';

abstract class MovieRepository {
  // Database
  Stream<List<dynamic>> getWatchlistStream(String userId, String status);

  // <-- NUOVO: Stream per il singolo Film/Serie per la Detail Page
  Stream<dynamic> getSingleMediaStream(String userId, int id);

  Future<void> saveMovie(Movie movie, String userId);
  Future<void> saveTvSeries(TvSeries series, String userId);

  Future<void> updateStatus(String userId, int id, String newStatus);
  Future<void> deleteItem(String userId, int id);
  Future<void> saveAnalysis(String userId, int id, String analysis);

  // API (TMDB)
  Future<List<Movie>> getMoviesByCategory(String categoryPath, {int page = 1});
  Future<List<TvSeries>> getTvSeriesByCategory(
    String categoryPath, {
    int page = 1,
  });

  Future<List<Review>> getReviews(int id, {bool isTv = false});
  Future<List<CastMember>> getCast(int id, {bool isTv = false});
  Future<List<Movie>> searchMovies(String query);
  Future<List<TvSeries>> searchTvSeries(String query);

  Future<String?> getTrailerKey(int id, {bool isTv = false});
  Future<WatchProvidersResult?> getWatchProviders(int id, {bool isTv = false});
}
