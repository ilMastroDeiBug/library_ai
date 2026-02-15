import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/ai_service.dart';

// --- DB USE CASES ---

class GetWatchlistUseCase {
  final MovieRepository repository;
  GetWatchlistUseCase(this.repository);

  Stream<List<dynamic>> call(String userId, String status) =>
      repository.getWatchlistStream(userId, status);
}

class ToggleMovieStatusUseCase {
  final MovieRepository repository;
  ToggleMovieStatusUseCase(this.repository);

  // CORRETTO: Aggiunto userId
  Future<String> call(String userId, int id, String currentStatus) async {
    final newStatus = currentStatus == 'watched' ? 'towatch' : 'watched';
    await repository.updateStatus(userId, id, newStatus);
    return newStatus;
  }
}

class SaveMovieUseCase {
  final MovieRepository repository;
  SaveMovieUseCase(this.repository);

  Future<void> call(Movie movie, String userId) =>
      repository.saveMovie(movie, userId);
}

class SaveMovieAnalysisUseCase {
  final MovieRepository repository;
  SaveMovieAnalysisUseCase(this.repository);

  // CORRETTO: Aggiunto userId
  Future<void> call(String userId, int movieId, String analysis) =>
      repository.saveAnalysis(userId, movieId, analysis);
}

class DeleteMovieUseCase {
  final MovieRepository repository;
  DeleteMovieUseCase(this.repository);

  // CORRETTO: Aggiunto userId
  Future<void> call(String userId, int movieId) =>
      repository.deleteItem(userId, movieId);
}

// --- API USE CASES (FILM) ---
// Questi non necessitano di userId perché usano TMDb (pubblico)

class GetMoviesByCategoryUseCase {
  final MovieRepository repository;
  GetMoviesByCategoryUseCase(this.repository);

  Future<List<Movie>> call(String path) => repository.getMoviesByCategory(path);
}

class GetMovieReviewsUseCase {
  final MovieRepository repository;
  GetMovieReviewsUseCase(this.repository);

  Future<List<Review>> call(int movieId) =>
      repository.getReviews(movieId, isTv: false);
}

class GetMovieCastUseCase {
  final MovieRepository repository;
  GetMovieCastUseCase(this.repository);

  Future<List<CastMember>> call(int movieId) =>
      repository.getCast(movieId, isTv: false);
}

class SearchMoviesUseCase {
  final MovieRepository repository;
  SearchMoviesUseCase(this.repository);

  Future<List<Movie>> call(String query) async {
    return await repository.searchMovies(query);
  }
}

class AnalyzeMovieUseCase {
  final MovieRepository repository;
  final AIService _aiService = AIService();

  AnalyzeMovieUseCase(this.repository);

  // CORRETTO: Aggiunto userId per poter salvare l'analisi
  Future<String> call(String userId, int movieId, String title) async {
    final analysis = await _aiService.analyzeMedia(
      title: title,
      type: 'movie',
      userProfile: "16 anni, Developer, Appassionato di Cinema",
      creator: "",
    );
    await repository.saveAnalysis(userId, movieId, analysis);
    return analysis;
  }
}
