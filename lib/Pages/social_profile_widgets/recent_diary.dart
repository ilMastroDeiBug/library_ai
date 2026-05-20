import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/vault_entry.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';
import 'package:library_ai/Pages/book_detail_page.dart';

/// Singola voce del Diario Recente nel profilo.
/// Tap sulla riga apre la detail page appropriata (film, serie, libro).
class RecentDiaryEntry extends StatelessWidget {
  final VaultEntry entry;

  const RecentDiaryEntry({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster ─────────────────────────────────────────────────────────
            _MiniPoster(posterUrl: entry.posterUrl, mediaType: entry.mediaType),

            const SizedBox(width: 14),

            // ── Info ───────────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(entry.addedAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (entry.reviewSnippet != null &&
                      entry.reviewSnippet!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '"${entry.reviewSnippet}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            _StatusChip(status: entry.status, mediaType: entry.mediaType),
          ],
        ),
      ),
    );
  }

  // ── Navigazione ─────────────────────────────────────────────────────────────

  void _openDetail(BuildContext context) {
    if (entry.mediaType == 'book') {
      _openBookDetail(context);
    } else {
      _openMediaDetail(context);
    }
  }

  void _openMediaDetail(BuildContext context) {
    // Recupera il row dalla cache Hive per ricostruire Movie o TvSeries
    final box = Hive.isBoxOpen('cinelib_cache')
        ? Hive.box('cinelib_cache')
        : null;

    dynamic media;

    if (box != null) {
      final rawRow = box.get('media_${entry.userId}_${entry.mediaId}');
      if (rawRow is Map) {
        final row = Map<String, dynamic>.from(rawRow);
        final rawData = row['raw_data'] is Map
            ? Map<String, dynamic>.from(row['raw_data'] as Map)
            : <String, dynamic>{};
        rawData['status'] = entry.status;

        if (entry.mediaType == 'tv') {
          media = TvSeries.fromFirestore(rawData, entry.mediaId);
        } else {
          media = Movie.fromFirestore(rawData, entry.mediaId);
        }
      }
    }

    // Fallback: costruisce un Movie/TvSeries minimale dai dati della VaultEntry
    media ??= entry.mediaType == 'tv'
        ? TvSeries(
            id: entry.mediaId,
            name: entry.title,
            overview: '',
            posterPath: _posterPathFromUrl(entry.posterUrl),
            backdropPath: '',
            voteAverage: entry.rating ?? 0.0,
            voteCount: 0,
            firstAirDate: '',
            popularity: 0,
            status: entry.status,
          )
        : Movie(
            id: entry.mediaId,
            title: entry.title,
            overview: '',
            posterPath: _posterPathFromUrl(entry.posterUrl),
            backdropPath: '',
            voteAverage: entry.rating ?? 0.0,
            voteCount: 0,
            releaseDate: '',
            popularity: 0,
            status: entry.status,
          );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailPage(media: media)),
    );
  }

  void _openBookDetail(BuildContext context) {
    final box = Hive.isBoxOpen('cinelib_cache')
        ? Hive.box('cinelib_cache')
        : null;

    Book? book;

    if (box != null) {
      // Cerca in tutti gli status
      for (final status in [
        'reading',
        'completed',
        'want_to_read',
        'dropped',
      ]) {
        final cached = box.get('books_${entry.userId}_$status');
        if (cached is! List) continue;
        for (final raw in cached) {
          if (raw is! Map) continue;
          final row = Map<String, dynamic>.from(raw as Map);
          final bookId = row['book_id']?.toString() ?? '';
          if (bookId.hashCode.abs() == entry.mediaId) {
            book = Book.fromFirestore(row, bookId);
            break;
          }
        }
        if (book != null) break;
      }
    }

    if (book != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailPage(book: book!)),
      );
    }
  }

  /// Estrae il path relativo dall'URL completo TMDB.
  String _posterPathFromUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    const base = 'https://image.tmdb.org/t/p/w342';
    return url.startsWith(base) ? url.substring(base.length) : '';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Oggi';
    if (diff.inDays == 1) return 'Ieri';
    if (diff.inDays < 7) return '${diff.inDays}g fa';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sett fa';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Mini Poster ───────────────────────────────────────────────────────────────

class _MiniPoster extends StatelessWidget {
  final String? posterUrl;
  final String mediaType;

  const _MiniPoster({this.posterUrl, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mediaType) {
      'tv' => Icons.tv_rounded,
      'book' => Icons.menu_book_rounded,
      _ => Icons.movie_rounded,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 70,
        height: 100,
        child: posterUrl != null
            ? CachedNetworkImage(
                imageUrl: posterUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _Fallback(icon: icon),
                placeholder: (_, __) => _Fallback(icon: icon),
              )
            : _Fallback(icon: icon),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final IconData icon;
  const _Fallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Icon(icon, color: Colors.white12, size: 22),
    );
  }
}

// ── Star Rating ───────────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half
              ? Icons.star_half_rounded
              : (filled ? Icons.star_rounded : Icons.star_border_rounded),
          size: 13,
          color: filled || half
              ? Colors.orangeAccent
              : Colors.white.withOpacity(0.2),
        );
      }),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  final String mediaType;

  const _StatusChip({required this.status, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolveStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String, Color) _resolveStatus(String status) {
    return switch (status) {
      'watched' ||
      'completed' => ('Visto', const Color.fromARGB(255, 214, 111, 42)),
      'watching' => ('In corso', const Color.fromARGB(255, 214, 111, 42)),
      'towatch' ||
      'want_to_read' => ('Da vedere', const Color.fromARGB(255, 214, 111, 42)),
      'reading' => ('Leggendo', const Color.fromARGB(255, 214, 111, 42)),
      'dropped' => ('Abbandonato', Colors.redAccent),
      _ => (status, Colors.white38),
    };
  }
}
