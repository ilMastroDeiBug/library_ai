import 'package:flutter/material.dart';
import '../../services/utility_services/tmdb_service.dart';
import 'review_model.dart';
import '../../pages/all_reviews_page.dart'; // Assicurati che il path sia corretto

class MovieReviewsSection extends StatelessWidget {
  final int movieId;
  final String movieTitle; // Aggiunto per passarlo alla pagina completa
  final TmdbService _tmdbService = TmdbService();

  // Colore Architect
  static const Color _brandColor = Colors.orangeAccent;

  MovieReviewsSection({
    super.key,
    required this.movieId,
    required this.movieTitle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _tmdbService.fetchMovieReviews(movieId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _brandColor),
          );
        }

        final allReviews = snapshot.data ?? [];
        if (allReviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Nessuna recensione disponibile dalla community globale.",
              style: TextStyle(
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Anteprima: prendiamo solo le prime 2
        final previewReviews = allReviews.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intestazione con tasto "Vedi Tutte"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "COMMUNITY",
                  style: TextStyle(
                    color: Colors.white30,
                    letterSpacing: 2.0,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllReviewsPage(
                          reviews: allReviews,
                          movieTitle: movieTitle,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "VEDI TUTTE",
                    style: TextStyle(
                      color: _brandColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mappa le recensioni di anteprima
            ...previewReviews.map((r) => _buildReviewPreviewCard(r)).toList(),
          ],
        );
      },
    );
  }

  // Card compatta per l'anteprima nella Home del Dettaglio
  Widget _buildReviewPreviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.author,
                style: const TextStyle(
                  color: _brandColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (review.rating != null) ...[
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  review.rating.toString(),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.content,
            maxLines: 3, // Limite per l'anteprima
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
