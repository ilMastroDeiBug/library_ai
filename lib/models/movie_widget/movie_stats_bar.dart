import 'package:flutter/material.dart';
import 'movie_model.dart';

class MovieStatsBar extends StatelessWidget {
  final Movie movie;

  // Costante di stile locale
  static const Color _brandColor = Colors.orangeAccent;

  const MovieStatsBar({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    // Estraiamo l'anno dalla data (es: "2024-05-12" -> "2024")
    final year = movie.releaseDate.split('-')[0];

    return Row(
      children: [
        _buildInfoTag(year),
        const SizedBox(width: 15),

        // Sezione Voto
        Row(
          children: [
            const Icon(Icons.star, color: _brandColor, size: 18),
            const SizedBox(width: 5),
            Text(
              movie.voteAverage.toStringAsFixed(1),
              style: const TextStyle(
                color: _brandColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              " / 10",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(width: 15),

        // Sezione Conteggio Voti
        Text(
          "${_formatVoteCount(movie.voteCount)} voti",
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
      ],
    );
  }

  // Helper Grafico: Tag (es. Anno)
  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper Logico: Formattazione Numeri (1200 -> 1.2k)
  String _formatVoteCount(int count) {
    if (count > 1000) {
      return "${(count / 1000).toStringAsFixed(1)}k";
    }
    return count.toString();
  }
}
