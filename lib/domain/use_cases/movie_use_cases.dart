import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/ai_service.dart';

// DB USE CASES
class GetWatchlistUseCase {
  final MovieRepository repository;
  GetWatchlistUseCase(this.repository);
  Stream<List<Movie>> call(String userId, String status) =>
      repository.getWatchlistStream(userId, status);
}

class ToggleMovieStatusUseCase {
  final MovieRepository repository;
  ToggleMovieStatusUseCase(this.repository);
  Future<String> call(int movieId, String currentStatus) async {
    final newStatus = currentStatus == 'watched' ? 'towatch' : 'watched';
    await repository.updateMovieStatus(movieId, newStatus);
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
  Future<void> call(int movieId, String analysis) =>
      repository.saveAnalysis(movieId, analysis);
}

class DeleteMovieUseCase {
  final MovieRepository repository;
  DeleteMovieUseCase(this.repository);
  Future<void> call(int movieId) => repository.deleteMovie(movieId);
}

// API USE CASES
class GetMoviesByCategoryUseCase {
  final MovieRepository repository;
  GetMoviesByCategoryUseCase(this.repository);
  Future<List<Movie>> call(String path) => repository.getMoviesByCategory(path);
}

class GetMovieReviewsUseCase {
  final MovieRepository repository;
  GetMovieReviewsUseCase(this.repository);
  Future<List<Review>> call(int movieId) => repository.getMovieReviews(movieId);
}

class GetMovieCastUseCase {
  final MovieRepository repository;
  GetMovieCastUseCase(this.repository);
  Future<List<CastMember>> call(int movieId) =>
      repository.getMovieCast(movieId);
}
// ... altri use cases esistenti ...

class AnalyzeMovieUseCase {
  final MovieRepository repository;
  // Per semplicità istanziamo qui il service, ma in futuro potresti iniettarlo
  final AIService _aiService = AIService();

  AnalyzeMovieUseCase(this.repository);

  Future<String> call(int movieId, String title) async {
    // 1. Chiede l'analisi all'AI
    final analysis = await _aiService.analyzeMedia(
      title: title,
      type: 'movie',
      // Puoi rendere questo profilo dinamico passandolo come parametro se vuoi
      userProfile: "16 anni, Developer, Appassionato di Cinema",
      creator:
          "", // Per i film il creator è meno rilevante nel prompt generico, o puoi passare il regista
    );

    // 2. Salva nel DB tramite il Repository
    await repository.saveAnalysis(movieId, analysis);

    return analysis;
  }
}
