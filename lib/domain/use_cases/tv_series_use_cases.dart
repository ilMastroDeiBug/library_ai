import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/ai_service.dart';
import 'package:library_ai/models/movie_widget/watch_provider_model.dart';

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

  Future<String> call(String userId, int id, String currentStatus) async {
    final newStatus = currentStatus == 'watched' ? 'towatch' : 'watched';
    await repository.updateStatus(userId, id, newStatus);
    return newStatus;
  }
}

class DeleteTvSeriesUseCase {
  final MovieRepository repository;
  DeleteTvSeriesUseCase(this.repository);

  Future<void> call(String userId, int seriesId) =>
      repository.deleteItem(userId, seriesId);
}

class SaveTvSeriesAnalysisUseCase {
  final MovieRepository repository;
  SaveTvSeriesAnalysisUseCase(this.repository);

  Future<void> call(String userId, int seriesId, String analysis) =>
      repository.saveAnalysis(userId, seriesId, analysis);
}

// --- API USE CASES (SERIE TV) ---

class GetTvSeriesByCategoryUseCase {
  final MovieRepository repository;
  GetTvSeriesByCategoryUseCase(this.repository);

  // FIX: Aggiunto il parametro opzionale 'page'
  Future<List<TvSeries>> call(String path, {int page = 1}) =>
      repository.getTvSeriesByCategory(path, page: page);
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

class GetTvSeriesTrailerUseCase {
  final MovieRepository repository;
  GetTvSeriesTrailerUseCase(this.repository);

  Future<String?> call(int seriesId) =>
      repository.getTrailerKey(seriesId, isTv: true);
}

class GetTvSeriesWatchProvidersUseCase {
  final MovieRepository repository;
  GetTvSeriesWatchProvidersUseCase(this.repository);

  Future<WatchProvidersResult?> call(int seriesId) =>
      repository.getWatchProviders(seriesId, isTv: true);
}
