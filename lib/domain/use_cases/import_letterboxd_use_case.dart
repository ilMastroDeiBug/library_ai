import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/review_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';

class ImportLetterboxdUseCase {
  final TmdbService tmdbService;
  final SaveMovieUseCase saveMovieUseCase;
  final SubmitReviewUseCase submitReviewUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;

  ImportLetterboxdUseCase({
    required this.tmdbService,
    required this.saveMovieUseCase,
    required this.submitReviewUseCase,
    required this.toggleFavoriteUseCase,
  });

  Future<void> importData({
    required List<List<dynamic>> rows,
    required String userId,
    required String fileName,
    required Function(int total, int processed) onProgress,
  }) async {
    // Check header to understand type of file
    if (rows.isEmpty) return;

    final nameLower = fileName.toLowerCase();
    final isWatchlist = nameLower.contains('watchlist');
    final isFavorites = nameLower.contains('favorite') || nameLower.contains('liked');
    final isRatings = nameLower.contains('rating');
    final isReviews = nameLower.contains('review');
    
    final header = rows.first.map((e) => e.toString().toLowerCase()).toList();
    int nameIndex = header.indexOf('name');
    int yearIndex = header.indexOf('year');
    int ratingIndex = header.indexOf('rating');
    int reviewIndex = header.indexOf('review');

    if (nameIndex == -1 || yearIndex == -1) return; // Non possiamo processare senza titolo e anno

    rows.removeAt(0);
    final total = rows.length;
    int processed = 0;

    for (var row in rows) {
      if (row.length <= nameIndex || row.length <= yearIndex) {
        processed++;
        onProgress(total, processed);
        continue;
      }

      String title = row[nameIndex].toString();
      String year = row[yearIndex].toString();
      
      final tmdbMovie = await tmdbService.searchMovieByTitleAndYear(title, year);
      
      if (tmdbMovie != null) {
        // Logica di smistamento basata sul nome del file
        if (isWatchlist) {
          await saveMovieUseCase.call(tmdbMovie.copyWith(status: 'towatch'), userId);
        } else {
          // Watched, Ratings, Reviews o Favorites presuppongono che il film sia stato visto
          await saveMovieUseCase.call(tmdbMovie.copyWith(status: 'watched'), userId);
          
          if (isFavorites) {
            // Seleziona o aggiungi ai preferiti
            await toggleFavoriteUseCase.call(userId, tmdbMovie.id, 'movie', tmdbMovie.title, tmdbMovie.fullPosterUrl);
          }

          if (isRatings && ratingIndex != -1 && row.length > ratingIndex) {
            double? rating = double.tryParse(row[ratingIndex].toString());
            if (rating != null && rating > 0) {
              await submitReviewUseCase.call(tmdbMovie.id, 'movie', userId, '', rating);
            }
          }

          if (isReviews && reviewIndex != -1 && row.length > reviewIndex) {
            String review = row[reviewIndex].toString();
            double rating = 0.0;
            if (ratingIndex != -1 && row.length > ratingIndex) {
               rating = double.tryParse(row[ratingIndex].toString()) ?? 0.0;
            }
            if (review.isNotEmpty) {
              await submitReviewUseCase.call(tmdbMovie.id, 'movie', userId, review, rating);
            }
          }
        }
      }

      processed++;
      onProgress(total, processed);
      
      // Rate limiting: 250ms delay
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}
