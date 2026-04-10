import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import '../../services/utility_services/ai_service.dart';

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

    // Toggle logico: se clicchi su uno già attivo, lo spengi ('none')
    final newStatus = (currentStatus == action) ? 'none' : action;

    try {
      if (media is Movie) {
        final updatedMovie = media.copyWith(status: newStatus);
        await sl<SaveMovieUseCase>().call(updatedMovie, user.id);
      } else if (media is TvSeries) {
        final updatedSeries = TvSeries(
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
        await sl<SaveTvSeriesUseCase>().call(updatedSeries, user.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Errore nel salvataggio. Riprova.")),
        );
      }
    }
  }

  Future<String?> handleAnalysis(BuildContext context, dynamic media) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return null;

    try {
      final aiService = AIService();
      final type = (media is TvSeries) ? 'tv' : 'movie';
      final title = (media is TvSeries) ? media.name : (media as Movie).title;

      final analysis = await aiService.analyzeMedia(
        title: title,
        type: type,
        userProfile:
            "16 anni, Architect, Developer, MMA", // Il tuo fantastico prompt AI
        creator: "",
      );

      if (media is Movie) {
        final updatedMovie = media.copyWith(aiAnalysis: analysis);
        await sl<SaveMovieUseCase>().call(updatedMovie, user.id);
      } else if (media is TvSeries) {
        final updatedSeries = TvSeries(
          id: media.id,
          name: media.name,
          overview: media.overview,
          posterPath: media.posterPath,
          backdropPath: media.backdropPath,
          voteAverage: media.voteAverage,
          voteCount: media.voteCount,
          firstAirDate: media.firstAirDate,
          status: media.status, // Manteniamo lo status originale!
          aiAnalysis: analysis,
        );
        await sl<SaveTvSeriesUseCase>().call(updatedSeries, user.id);
      }

      return analysis;
    } catch (e) {
      debugPrint("AI Error: $e");
      return null;
    }
  }
}
