import 'package:flutter/material.dart';
import '../models/book_model.dart';
// Importa la pagina di dettaglio (che creeremo tra un secondo)
import '../pages/book_detail_page.dart';

class BookCard extends StatelessWidget {
  final Book book; // Ora riceviamo un oggetto Libro vero!

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigazione alla pagina di dettaglio
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
        );
      },
      child: Container(
        width: 120, // Larghezza fissa per coerenza nella lista orizzontale
        margin: const EdgeInsets.only(right: 15), // Spazio tra le card
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
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
                            _buildPlaceholder(), // Se l'immagine non carica
                      )
                    : _buildPlaceholder(),
              ),

              // --- 2. INFO ---
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blueGrey[900],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
}
