import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/app_mode.dart';
import '../../pages/book_detail_page.dart';
import '../../pages/movie_detail_page.dart';

class SearchResultTile extends StatelessWidget {
  final dynamic item;
  final AppMode mode;

  const SearchResultTile({super.key, required this.item, required this.mode});

  @override
  Widget build(BuildContext context) {
    String title = "";
    String subtitle = "";
    String imageUrl = "";
    IconData defaultIcon = Icons.movie;
    VoidCallback onTap = () {};

    // Smistamento logico
    if (item is Book) {
      title = item.title;
      subtitle = item.author;
      imageUrl = item.thumbnailUrl;
      defaultIcon = Icons.book;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailPage(book: item)),
      );
    } else if (item is Movie) {
      title = item.title;
      subtitle = item.releaseDate.isNotEmpty
          ? "Film (${item.releaseDate.split('-')[0]})"
          : "Film";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.movie_outlined;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is TvSeries) {
      title = item.name;
      subtitle = item.firstAirDate.isNotEmpty
          ? "Serie TV (${item.firstAirDate.split('-')[0]})"
          : "Serie TV";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.tv_outlined;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    }

    final activeColor = mode == AppMode.books
        ? Colors.orangeAccent
        : Colors.cyanAccent;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 55,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholder(defaultIcon),
                      )
                    : _buildPlaceholder(defaultIcon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: activeColor.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 55,
      height: 80,
      color: Colors.grey[900],
      child: Icon(icon, color: Colors.white24, size: 24),
    );
  }
}
