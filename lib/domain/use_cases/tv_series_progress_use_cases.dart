import '../repositories/tv_progress_repository.dart';
import '../entities/tv_series_progress.dart';

class GetSeriesProgressUseCase {
  final TvProgressRepository repository;
  GetSeriesProgressUseCase(this.repository);
  Stream<TvSeriesProgress?> call(String userId, int seriesId) =>
      repository.watchProgress(userId, seriesId);
}

class GetAllUserProgressUseCase {
  final TvProgressRepository repository;
  GetAllUserProgressUseCase(this.repository);
  Stream<List<TvSeriesProgress>> call(String userId) =>
      repository.watchAllUserProgress(userId);
}

class DeleteSeriesProgressUseCase {
  final TvProgressRepository repository;
  DeleteSeriesProgressUseCase(this.repository);
  Future<void> call(String userId, int seriesId) async {
    await repository.deleteProgress(userId, seriesId);
  }
}

// LOGICA BULK INTELLIGENTE
class ToggleEpisodeWatchedUseCase {
  final TvProgressRepository repository;
  ToggleEpisodeWatchedUseCase(this.repository);

  Future<void> call(
    String userId,
    int seriesId,
    int targetSeason,
    int targetEpisode,
    Map<int, int> episodesPerSeason,
    bool isCurrentlyWatched,
  ) async {
    final progress =
        await repository.getProgress(userId, seriesId) ??
        TvSeriesProgress(userId: userId, seriesId: seriesId);

    // 1. Generiamo una lista "piatta" di tutti gli episodi possibili in ordine cronologico
    List<String> allEpisodesInOrder = [];
    final sortedSeasons = episodesPerSeason.keys.toList()..sort();

    for (int season in sortedSeasons) {
      final epCount = episodesPerSeason[season] ?? 0;
      for (int ep = 1; ep <= epCount; ep++) {
        allEpisodesInOrder.add("S$season:E$ep");
      }
    }

    final targetId = "S$targetSeason:E$targetEpisode";
    final targetIndex = allEpisodesInOrder.indexOf(targetId);
    if (targetIndex == -1) return; // Sicurezza

    List<String> updatedEpisodes = [];
    int newStreak = progress.currentStreak;
    DateTime? newDate = progress.lastWatchedDate;

    if (isCurrentlyWatched) {
      // RIMUOVI IN BLOCCO: Mantengo solo gli episodi PRIMA di quello cliccato
      List<String> episodesToKeep = allEpisodesInOrder.sublist(0, targetIndex);
      // Faccio l'intersezione con quelli che aveva già visto
      updatedEpisodes = progress.watchedEpisodes
          .where((e) => episodesToKeep.contains(e))
          .toList();

      // Se svuoto la lista, resetto la streak
      if (updatedEpisodes.isEmpty) {
        newStreak = 0;
        newDate = null;
      }
    } else {
      // AGGIUNGI IN BLOCCO: Marco come visti tutti da S1:E1 fino a quello cliccato
      List<String> episodesToAdd = allEpisodesInOrder.sublist(
        0,
        targetIndex + 1,
      );
      final Set<String> uniqueEpisodes = {
        ...progress.watchedEpisodes,
        ...episodesToAdd,
      };
      updatedEpisodes = uniqueEpisodes.toList();

      // Logica Streak (Aumenta solo in aggiunta)
      int delta = progress.deltaDays;
      if (progress.isLost || delta == -1) {
        newStreak = 1;
      } else if (delta == 1) {
        newStreak += 1;
      }
      newDate = DateTime.now();
    }

    final updatedProgress = progress.copyWith(
      watchedEpisodes: updatedEpisodes,
      streakCount: newStreak,
      lastWatchedDate: newDate,
    );

    await repository.saveProgress(updatedProgress);
  }
}
