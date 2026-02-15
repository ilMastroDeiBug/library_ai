import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/ai_service.dart';

// --- DB USE CASES (SERIE TV) ---

class SaveTvSeriesUseCase {
  final MovieRepository repository;
  SaveTvSeriesUseCase(this.repository);

  Future<void> call(TvSeries series, String userId) =>
      repository.saveTvSeries(series, userId);
}

class ToggleTvSeriesStatusUseCase {
  final MovieRepository repository;
  ToggleTvSeriesStatusUseCase(this.repository);

  // CORRETTO: Aggiunto userId
  Future<String> call(String userId, int id, String currentStatus) async {
    final newStatus = currentStatus == 'watched' ? 'towatch' : 'watched';
    await repository.updateStatus(userId, id, newStatus);
    return newStatus;
  }
}

class DeleteTvSeriesUseCase {
  final MovieRepository repository;
  DeleteTvSeriesUseCase(this.repository);

  // CORRETTO: Aggiunto userId
  Future<void> call(String userId, int seriesId) =>
      repository.deleteItem(userId, seriesId);
}

class SaveTvSeriesAnalysisUseCase {
  final MovieRepository repository;
  SaveTvSeriesAnalysisUseCase(this.repository);

  // CORRETTO: Aggiunto userId
  Future<void> call(String userId, int seriesId, String analysis) =>
      repository.saveAnalysis(userId, seriesId, analysis);
}

// --- API USE CASES (SERIE TV) ---

class GetTvSeriesByCategoryUseCase {
  final MovieRepository repository;
  GetTvSeriesByCategoryUseCase(this.repository);

  Future<List<TvSeries>> call(String path) =>
      repository.getTvSeriesByCategory(path);
}

class GetTvSeriesReviewsUseCase {
  final MovieRepository repository;
  GetTvSeriesReviewsUseCase(this.repository);

  Future<List<Review>> call(int seriesId) =>
      repository.getReviews(seriesId, isTv: true);
}

class GetTvSeriesCastUseCase {
  final MovieRepository repository;
  GetTvSeriesCastUseCase(this.repository);

  Future<List<CastMember>> call(int seriesId) =>
      repository.getCast(seriesId, isTv: true);
}

class SearchTvSeriesUseCase {
  final MovieRepository repository;
  SearchTvSeriesUseCase(this.repository);

  Future<List<TvSeries>> call(String query) async {
    return await repository.searchTvSeries(query);
  }
}

class AnalyzeTvSeriesUseCase {
  final MovieRepository repository;
  final AIService _aiService = AIService();

  AnalyzeTvSeriesUseCase(this.repository);

  // CORRETTO: Aggiunto userId per salvare l'analisi
  Future<String> call(String userId, int seriesId, String name) async {
    final analysis = await _aiService.analyzeMedia(
      title: name,
      type: 'tv series',
      userProfile: "16 anni, Developer, Appassionato di Cinema",
      creator: "",
    );
    await repository.saveAnalysis(userId, seriesId, analysis);
    return analysis;
  }
}
