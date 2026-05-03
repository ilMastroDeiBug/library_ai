import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart'; // <-- IMPORT PREFERITI
import '../../services/utility_services/ai_service.dart';

class MovieDetailLogic {
  final AIService _aiService;

  MovieDetailLogic({AIService? aiService})
    : _aiService = aiService ?? AIService();

  Future<void> handleStatusAction(
    BuildContext context,
    dynamic media,
    String action,
    String currentStatus,
  ) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted) _showMinimalSnackBar(context, "Accedi per salvare.");
      return;
    }

    final isRemoving = currentStatus == action;
    final newStatus = isRemoving ? 'none' : action;

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
          popularity: media.popularity,
        );
        await sl<SaveTvSeriesUseCase>().call(updatedSeries, user.id);
      }

      if (context.mounted) {
        _showMinimalSnackBar(
          context,
          isRemoving
              ? "Rimosso dalla Watchlist"
              : (action == 'watched'
                    ? "Segnato come Visto"
                    : "Aggiunto ai Da Vedere"),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMinimalSnackBar(context, "Errore nel salvataggio. Riprova.");
      }
    }
  }

  // --- NUOVA LOGICA PREFERITI ---
  Future<void> toggleFavorite(BuildContext context, dynamic media) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted)
        _showMinimalSnackBar(context, "Accedi per aggiungere ai preferiti.");
      return;
    }

    try {
      final isTv = media is TvSeries;
      final int itemId = media.id;
      final String itemType = isTv ? 'tv' : 'movie';
      final String title = isTv ? media.name : (media as Movie).title;
      final String posterUrl = isTv
          ? media.fullPosterUrl
          : (media as Movie).fullPosterUrl;

      // Chiama l'Use Case che fa il toggle nel DB
      final isAdded = await sl<ToggleFavoriteUseCase>().call(
        user.id,
        itemId,
        itemType,
        title,
        posterUrl,
      );

      if (context.mounted) {
        _showMinimalSnackBar(
          context,
          isAdded ? "Aggiunto ai Preferiti ❤️" : "Rimosso dai Preferiti 💔",
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMinimalSnackBar(
          context,
          "Errore nell'aggiornamento dei preferiti.",
        );
      }
    }
  }

  Future<String?> handleAnalysis(BuildContext context, dynamic media) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return null;

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
          status: media.status,
          aiAnalysis: analysis,
          popularity: media.popularity,
        );
        await sl<SaveTvSeriesUseCase>().call(updatedSeries, user.id);
      }

      return analysis;
    } catch (e) {
      debugPrint("AI Error: $e");
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
