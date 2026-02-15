import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';

class MovieDetailLogic {
  Future<void> handleStatusAction(
    BuildContext context,
    dynamic media,
    String action,
    String currentStatus,
  ) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Accedi per salvare."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final newStatus = (currentStatus == action) ? 'none' : action;

    try {
      if (media is Movie) {
        await sl<SaveMovieUseCase>().call(
          media.copyWith(status: newStatus),
          user.uid,
        );
      } else if (media is TvSeries) {
        final updated = TvSeries(
          id: media.id,
          name: media.name,
          overview: media.overview,
          posterPath: media.posterPath,
          backdropPath: media.backdropPath,
          voteAverage: media.voteAverage,
          voteCount: media.voteCount,
          firstAirDate: media.firstAirDate,
          status: newStatus,
          aiAnalysis: media.aiAnalysis,
        );
        await sl<SaveTvSeriesUseCase>().call(updated, user.uid);
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Errore salvataggio")));
    }
  }

  Future<String?> handleAnalysis(BuildContext context, dynamic media) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return null;

    try {
      if (media is Movie) {
        return await sl<AnalyzeMovieUseCase>().call(
          user.uid,
          media.id,
          media.title,
        );
      } else if (media is TvSeries) {
        return await sl<AnalyzeTvSeriesUseCase>().call(
          user.uid,
          media.id,
          media.name,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
