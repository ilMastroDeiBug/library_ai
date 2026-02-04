import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating; // Es: 4.5
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 14,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        // Logica matematica per le stelle
        // index va da 0 a 4 (Stella 1, Stella 2, etc.)
        int starPosition = index + 1;

        if (rating >= starPosition) {
          // Esempio: Voto 4.5. Stella 1, 2, 3, 4 sono PIENE
          return Icon(Icons.star, size: size, color: color);
        } else if (rating > (starPosition - 1)) {
          // Esempio: Voto 4.5. Stella 5.
          // 4.5 è maggiore di 4 ma minore di 5 -> MEZZA STELLA
          return Icon(Icons.star_half, size: size, color: color);
        } else {
          // Esempio: Voto 3.0. Stella 4 e 5 -> VUOTE
          return Icon(
            Icons.star_border,
            size: size,
            color: color.withOpacity(0.3),
          );
        }
      }),
    );
  }
}
