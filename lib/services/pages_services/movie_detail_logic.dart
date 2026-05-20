import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/domain/use_cases/tv_series_progress_use_cases.dart';
import 'package:library_ai/services/utility_services/watchlist_realtime_notifier.dart';
import '../../services/utility_services/ai_service.dart';
import '../../services/utility_services/offline_action_guard.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class MovieDetailLogic {
  final AIService _aiService;

  MovieDetailLogic({AIService? aiService})
    : _aiService = aiService ?? AIService();

  Future<bool> handleStatusAction(
    BuildContext context,
    dynamic media,
    String action,
    String currentStatus,
  ) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted) _showMinimalSnackBar(context, AppLocalizations.of(context)!.logicLoginToSave);
      return false;
    }

    final isRemoving = currentStatus == action;
    final newStatus = isRemoving ? 'none' : action;
    final int mediaId = media.id as int;
    final hadPreviousOptimisticStatus = globalOptimisticStatus.value
        .containsKey(mediaId);
    final previousOptimisticStatus = globalOptimisticStatus.value[mediaId];

    setOptimisticMediaStatus(mediaId, newStatus);

    dynamic mediaToSave = media;

    if (media is TvSeries && newStatus != 'none') {
      try {
        final fullTvData = await sl<TmdbService>().getTvSeriesDetails(media.id);
        mediaToSave = media.copyWith(
          seasons: fullTvData.seasons,
          runtime: fullTvData.runtime,
          numberOfEpisodes: fullTvData.numberOfEpisodes,
          status: newStatus,
        );
      } catch (e) {
        mediaToSave = media.copyWith(status: newStatus);
      }
    } else if (media is Movie && newStatus != 'none') {
      try {
        final fullMovieData = await sl<TmdbService>().getMovieDetails(media.id);
        mediaToSave = media.copyWith(
          runtime: fullMovieData.runtime,
          status: newStatus,
        );
      } catch (e) {
        mediaToSave = media.copyWith(status: newStatus);
      }
    } else if (media is TvSeries || media is Movie) {
      mediaToSave = media.copyWith(status: newStatus);
    }

    try {
      if (isRemoving) {
        if (media is Movie) {
          await sl<DeleteMovieUseCase>().call(user.id, media.id);
        } else {
          await sl<DeleteTvSeriesUseCase>().call(user.id, media.id);
        }
      } else {
        if (mediaToSave is Movie) {
          await sl<SaveMovieUseCase>().call(mediaToSave, user.id);
        } else {
          await sl<SaveTvSeriesUseCase>().call(mediaToSave, user.id);
        }
      }

      if (media is TvSeries && newStatus != 'watching') {
        try {
          await sl<DeleteSeriesProgressUseCase>().call(user.id, media.id);
        } catch (_) {}
      }

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        String msg = l10n.logicRemovedFromLibrary;
        if (!isRemoving) {
          if (action == 'watched') msg = l10n.logicMarkedAsWatched;
          if (action == 'towatch') msg = l10n.logicAddedToWatchlist;
          if (action == 'watching') msg = l10n.logicAddedToWatching;
        }

        _showMinimalSnackBar(context, msg);
      }
      clearOptimisticMediaStatus(mediaId);
      return true;
    } catch (e) {
      if (hadPreviousOptimisticStatus && previousOptimisticStatus != null) {
        setOptimisticMediaStatus(mediaId, previousOptimisticStatus);
      } else {
        clearOptimisticMediaStatus(mediaId);
      }
      if (context.mounted)
        _showMinimalSnackBar(context, AppLocalizations.of(context)!.logicSaveError);
      return false;
    }
  }

  Future<bool> toggleFavorite(BuildContext context, dynamic media) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted)
        _showMinimalSnackBar(context, AppLocalizations.of(context)!.logicLoginToFavorite);
      return false;
    }

    try {
      final isTv = media is TvSeries;
      final isAdded = await sl<ToggleFavoriteUseCase>().call(
        user.id,
        media.id,
        isTv ? 'tv' : 'movie',
        isTv ? media.name : (media as Movie).title,
        isTv ? media.fullPosterUrl : (media as Movie).fullPosterUrl,
      );

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showMinimalSnackBar(
          context,
          isAdded ? l10n.logicAddedToFavorites : l10n.logicRemovedFromFavorites,
        );
      }
      return isAdded;
    } catch (e) {
      if (context.mounted)
        _showMinimalSnackBar(
          context,
          AppLocalizations.of(context)!.logicFavoriteError,
        );
      rethrow;
    }
  }

  Future<String?> handleAnalysis(BuildContext context, dynamic media) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return null;

    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return null;

    try {
      final type = (media is TvSeries) ? 'tv' : 'movie';
      final title = (media is TvSeries) ? media.name : (media as Movie).title;
      final analysis = await _aiService.analyzeMedia(
        title: title,
        type: type,
        userProfile: "16 anni, Architect, Developer, MMA",
        creator: "",
      );

      if (media is Movie) {
        await sl<SaveMovieUseCase>().call(
          media.copyWith(aiAnalysis: analysis),
          user.id,
        );
      } else if (media is TvSeries) {
        await sl<SaveTvSeriesUseCase>().call(
          media.copyWith(aiAnalysis: analysis),
          user.id,
        );
      }
      return analysis;
    } catch (e) {
      return null;
    }
  }

  void _showMinimalSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
