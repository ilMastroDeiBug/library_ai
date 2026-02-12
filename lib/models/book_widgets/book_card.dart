import 'package:flutter/material.dart';
import '/models/book_widgets/book_model.dart';
import '/pages/book_detail_page.dart';
// IMPORTANTE: Importa il widget che abbiamo creato al punto 1
import 'star_rating.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
        );
      },
      child: Container(
        width: 120, // Larghezza fissa della card
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. COPERTINA ---
              Expanded(
                child: book.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        book.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // --- 2. INFO ---
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titolo
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Autore
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // --- 3. STELLINE DI PRECISIONE (MODIFICATO) ---
                    if (book.averageRating != null) ...[
                      const SizedBox(height: 8), // Spazio extra
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // A. IL NUMERO (Es. 4.5)
                          Text(
                            book.averageRating?.toStringAsFixed(1) ?? "N/D",
                            style: const TextStyle(
                              color: Colors.white, // Numero Bianco
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),

                          // B. LE STELLE (Gialle e Grigie)
                          StarRating(
                            rating: book.averageRating?.toDouble() ?? 0.0,
                            size: 10, // Stelle piccole ed eleganti
                            color: Colors.amber,
                          ),

                          const SizedBox(width: 4),

                          // C. IL CONTEGGIO (Es. (120))
                          Expanded(
                            // Per evitare overflow se il numero è lungo
                            child: Text(
                              "(${book.ratingsCount ?? 0})",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 9,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white24),
      ),
    );
  }
}
