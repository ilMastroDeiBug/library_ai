import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/book.dart'; // O domain/entities/book.dart
import '../../pages/book_detail_page.dart';

class SearchResultTile extends StatelessWidget {
  final Book book;

  const SearchResultTile({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.thumbnailUrl.isNotEmpty
              ? Image.network(
                  book.thumbnailUrl,
                  width: 50,
                  height: 75, // Fissiamo l'altezza per evitare scatti
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        title: Text(
          book.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            book.author,
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.white.withOpacity(0.3),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 75,
      color: Colors.grey[800],
      child: const Icon(Icons.book, color: Colors.white24),
    );
  }
}
