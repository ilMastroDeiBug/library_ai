import '../entities/movie.dart';
import '../entities/tv_series.dart'; // Importa la nuova entità
import '../../models/movie_widget/review_model.dart';
import '../../models/movie_widget/cast_model.dart';

abstract class MovieRepository {
  // Database (Firestore)
  Stream<List<dynamic>> getWatchlistStream(String userId, String status);

  Future<void> saveMovie(Movie movie, String userId);
  Future<void> saveTvSeries(TvSeries series, String userId);

  // MODIFICA: Aggiunto userId a questi tre metodi
  Future<void> updateStatus(String userId, int id, String newStatus);
  Future<void> deleteItem(String userId, int id);
  Future<void> saveAnalysis(String userId, int id, String analysis);

  // API (TMDB) - Questi restano uguali
  Future<List<Movie>> getMoviesByCategory(String categoryPath);
  Future<List<TvSeries>> getTvSeriesByCategory(String categoryPath);
  Future<List<Review>> getReviews(int id, {bool isTv = false});
  Future<List<CastMember>> getCast(int id, {bool isTv = false});
  Future<List<Movie>> searchMovies(String query);
  Future<List<TvSeries>> searchTvSeries(String query);
}
