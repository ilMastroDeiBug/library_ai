import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';

class MovieRepositoryImpl implements MovieRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TmdbService _tmdbService = TmdbService();

  @override
  Stream<List<Movie>> getWatchlistStream(String userId, String status) {
    return _firestore
        .collection('movies')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Parsing sicuro ID
            final int id = int.tryParse(doc.id) ?? 0;
            return Movie.fromFirestore(doc.data(), id);
          }).toList();
        });
  }

  @override
  Future<void> saveMovie(Movie movie, String userId) async {
    final data = movie.toMap();
    data['userId'] = userId;
    data['timestamp'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('movies')
        .doc(movie.id.toString())
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateMovieStatus(int movieId, String newStatus) async {
    await _firestore.collection('movies').doc(movieId.toString()).update({
      'status': newStatus,
    });
  }

  @override
  Future<void> deleteMovie(int movieId) async {
    await _firestore.collection('movies').doc(movieId.toString()).delete();
  }

  @override
  Future<void> saveAnalysis(int movieId, String analysis) async {
    await _firestore.collection('movies').doc(movieId.toString()).update({
      'aiAnalysis': analysis,
    });
  }

  // --- API TMDB ---
  @override
  Future<List<Movie>> getMoviesByCategory(String categoryPath) async {
    return await _tmdbService.fetchByCategory(categoryPath);
  }

  @override
  Future<List<Review>> getMovieReviews(int movieId) async {
    return await _tmdbService.fetchMovieReviews(movieId);
  }

  @override
  Future<List<CastMember>> getMovieCast(int movieId) async {
    return await _tmdbService.fetchMovieCast(movieId);
  }
}
