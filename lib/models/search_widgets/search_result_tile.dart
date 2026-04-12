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

    // Estrazione Dati
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
          ? "Film • ${item.releaseDate.split('-')[0]}"
          : "Film";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.movie_creation_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    } else if (item is TvSeries) {
      title = item.name;
      subtitle = item.firstAirDate.isNotEmpty
          ? "Serie TV • ${item.firstAirDate.split('-')[0]}"
          : "Serie TV";
      imageUrl = item.fullPosterUrl;
      defaultIcon = Icons.live_tv_rounded;
      onTap = () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
      );
    }

    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: Container(
        color: Colors.transparent, // Niente card grigie, nero totale sotto
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // 1. LOCANDINA (Netflix Style 2:3)
            ClipRRect(
              borderRadius: BorderRadius.circular(
                6,
              ), // Bordo leggermente arrotondato
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 70,
                      height: 105, // Proporzione esatta locandine
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholder(defaultIcon),
                    )
                  : _buildPlaceholder(defaultIcon),
            ),

            const SizedBox(width: 16),

            // 2. TESTI (Titolo Bianco Bold, Sottotitolo Grigio)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5), // Grigio elegante
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 3. ICONA PLAY (Stile ricerca Netflix)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                mode == AppMode.books
                    ? Icons.menu_book_rounded
                    : Icons.play_circle_outline_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: 70,
      height: 105,
      color: Colors.white.withOpacity(0.05), // Grigio scuro placeholder
      child: Center(child: Icon(icon, color: Colors.white24, size: 30)),
    );
  }
}
