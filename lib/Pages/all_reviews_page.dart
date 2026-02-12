import 'package:flutter/material.dart';
import '../models/movie_widget/review_model.dart';

class AllReviewsPage extends StatelessWidget {
  final List<Review> reviews;
  final String movieTitle;

  const AllReviewsPage({
    super.key,
    required this.reviews,
    required this.movieTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Recensioni: $movieTitle",
          style: const TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        // Qui in futuro aggiungeremo le Actions per il Sorting
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return _buildFullReviewCard(reviews[index]);
        },
      ),
    );
  }

  Widget _buildFullReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: review.avatarPath != null
                    ? NetworkImage(review.avatarPath!)
                    : null,
                child: review.avatarPath == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.author,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (review.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orangeAccent,
                          size: 14,
                        ),
                        Text(
                          " ${review.rating}",
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            review.content,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
