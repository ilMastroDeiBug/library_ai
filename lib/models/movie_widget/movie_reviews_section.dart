import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'review_model.dart';
import '../../pages/all_reviews_page.dart';

class MovieReviewsSection extends StatelessWidget {
  final int id;
  final String title;
  final bool isTvSeries; // Flag

  static const Color _brandColor = Colors.orangeAccent;

  const MovieReviewsSection({
    super.key,
    required this.id,
    required this.title,
    this.isTvSeries = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      // CLEAN ARCHITECTURE CALL
      future: isTvSeries
          ? sl<GetTvSeriesReviewsUseCase>().call(id)
          : sl<GetMovieReviewsUseCase>().call(id),

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
              "Nessuna recensione disponibile.",
              style: TextStyle(
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final previewReviews = allReviews.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          movieTitle: title,
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
            ...previewReviews.map((r) => _buildReviewPreviewCard(r)),
          ],
        );
      },
    );
  }

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
            maxLines: 3,
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
