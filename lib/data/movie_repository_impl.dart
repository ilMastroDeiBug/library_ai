import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';

class MovieRepositoryImpl implements MovieRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TmdbService _tmdbService = TmdbService();

  // Helper per il percorso della watchlist dell'utente
  CollectionReference _watchlistRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('watchlist');

  @override
  Stream<List<dynamic>> getWatchlistStream(String userId, String status) {
    return _watchlistRef(
      userId,
    ).where('status', isEqualTo: status).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] ?? 'movie';
        final int id = int.tryParse(doc.id) ?? 0;
        return (type == 'tv')
            ? TvSeries.fromFirestore(data, id)
            : Movie.fromFirestore(data, id);
      }).toList();
    });
  }

  @override
  Future<void> saveMovie(Movie movie, String userId) async {
    final data = movie.toMap();
    data['type'] = 'movie';
    data['timestamp'] = FieldValue.serverTimestamp();
    await _watchlistRef(
      userId,
    ).doc(movie.id.toString()).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> saveTvSeries(TvSeries series, String userId) async {
    final data = series.toMap();
    data['type'] = 'tv';
    data['timestamp'] = FieldValue.serverTimestamp();
    await _watchlistRef(
      userId,
    ).doc(series.id.toString()).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateStatus(String userId, int id, String newStatus) async {
    await _watchlistRef(
      userId,
    ).doc(id.toString()).update({'status': newStatus});
  }

  @override
  Future<void> deleteItem(String userId, int id) async {
    await _watchlistRef(userId).doc(id.toString()).delete();
  }

  @override
  Future<void> saveAnalysis(String userId, int id, String analysis) async {
    await _watchlistRef(userId).doc(id.toString()).set({
      'aiAnalysis': analysis,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- METODI API TMDB ---
  @override
  Future<List<Movie>> getMoviesByCategory(String categoryPath) async {
    if (categoryPath == 'trending') {
      return await _tmdbService.fetchTrendingMovies();
    }
    if (categoryPath.contains('with_genres=')) {
      final genreId = categoryPath.split('=').last;
      return await _tmdbService.fetchMoviesByGenre(genreId);
    }
    return await _tmdbService.fetchMoviesByCategory(categoryPath);
  }

  @override
  Future<List<TvSeries>> getTvSeriesByCategory(String categoryPath) async {
    if (categoryPath == 'trending') return await _tmdbService.fetchTvTrending();
    if (categoryPath.contains('with_genres=')) {
      final genreId = categoryPath.split('=').last;
      return await _tmdbService.fetchTvByGenre(genreId);
    }
    return await _tmdbService.fetchTvSeriesByCategory(categoryPath);
  }

  @override
  Future<List<Review>> getReviews(int id, {bool isTv = false}) async =>
      _tmdbService.fetchReviews(id, isTv: isTv);

  @override
  Future<List<CastMember>> getCast(int id, {bool isTv = false}) async =>
      _tmdbService.fetchCast(id, isTv: isTv);

  @override
  Future<List<Movie>> searchMovies(String query) async =>
      _tmdbService.searchMovies(query);

  @override
  Future<List<TvSeries>> searchTvSeries(String query) async =>
      _tmdbService.searchTvSeries(query);
}
