import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import 'review_model.dart';
import '../../pages/all_reviews_page.dart';

class MovieReviewsSection extends StatelessWidget {
  final int id;
  final String title;
  final bool isTvSeries;

  // COLORI RICALIBRATI: Un ambra più nobile e meno "neon"
  static const Color _brandAmber = Color(0xFFFFB300);
  static const Color _cardBackground = Color(0xFF1E1E20);

  const MovieReviewsSection({
    super.key,
    required this.id,
    required this.title,
    this.isTvSeries = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<LanguageService>(),
      builder: (context, _) => FutureBuilder<List<Review>>(
        key: ValueKey('reviews_${id}_${isTvSeries}_${sl<LanguageService>().currentLanguage}'),
        future: isTvSeries
            ? sl<GetTvSeriesReviewsUseCase>().call(id)
            : sl<GetMovieReviewsUseCase>().call(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _brandAmber,
                strokeWidth: 2,
              ),
            );
          }

          final allReviews = snapshot.data ?? [];
          if (allReviews.isEmpty) return _buildEmptyState();

          final previewReviews = allReviews.take(2).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, allReviews),
              const SizedBox(height: 15),
              ...previewReviews.map((r) => _buildReviewCard(r)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<Review> allReviews) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "REAZIONI COMMUNITY", // Nome più "serio"
          style: TextStyle(
            color: Colors.white70,
            letterSpacing: 1.5,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AllReviewsPage(reviews: allReviews, movieTitle: title),
            ),
          ),
          child: const Text(
            "SCOPRI TUTTE",
            style: TextStyle(
              color: _brandAmber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
        // Rimosso il border problematico da qui
      ),
      // Usiamo ClipRRect per assicurarci che tutto rispetti i bordi arrotondati
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          // Fa sì che la linea laterale sia alta quanto il testo
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LA LINEA LATERALE (Sostituisce il border left)
              Container(width: 4, color: _brandAmber.withOpacity(0.5)),
              // IL CONTENUTO DELLA CARD
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            backgroundImage: review.avatarPath != null
                                ? NetworkImage(review.avatarPath!)
                                : null,
                            child: review.avatarPath == null
                                ? const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white24,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              review.author,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (review.rating != null)
                            _buildRating(review.rating!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: _brandAmber, size: 16),
        const SizedBox(width: 4),
        Text(
          rating.toString(),
          style: const TextStyle(
            color: _brandAmber,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "Ancora nessun commento nel database.",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
