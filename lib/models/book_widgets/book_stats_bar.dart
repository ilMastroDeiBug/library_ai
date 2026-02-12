import 'package:flutter/material.dart';
import '/models/book_widgets/book_model.dart';
import '../../pages/reviews_page.dart';
import 'star_rating.dart'; // IMPORTA IL TUO WIDGET STELLE

class BookStatsBar extends StatelessWidget {
  final Book book;

  const BookStatsBar({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pagine
            _buildStatColumn(
              label: "LUNGHEZZA",
              icon: Icons.menu_book_rounded,
              value: book.pageCount != null ? "${book.pageCount}" : "-",
              valueSize: 16,
            ),

            Container(width: 1, color: Colors.white12),

            // Recensioni (Cliccabile)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReviewsPage(book: book)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "VALUTAZIONE",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Usiamo il tuo widget StarRating modulare!
                      StarRating(
                        rating: book.averageRating?.toDouble() ?? 0.0,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        book.averageRating?.toStringAsFixed(1) ?? "N/D",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${book.ratingsCount ?? 0} recensioni",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required IconData icon,
    required String value,
    double? valueSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: valueSize,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
