import '../entities/tv_series_progress.dart';

abstract class TvProgressRepository {
  Future<TvSeriesProgress?> getProgress(String userId, int seriesId);
  Future<void> saveProgress(TvSeriesProgress progress);
  Stream<TvSeriesProgress?> watchProgress(String userId, int seriesId);
  Stream<List<TvSeriesProgress>> watchAllUserProgress(String userId);
  Future<void> deleteProgress(String userId, int seriesId); // NUOVO
}
