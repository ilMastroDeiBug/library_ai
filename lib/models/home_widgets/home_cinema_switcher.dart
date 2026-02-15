import 'package:flutter/material.dart';
import '../app_mode.dart';

class HomeCinemaSwitcher extends StatelessWidget {
  final CinemaType selectedType;
  final Function(CinemaType) onTypeChanged;

  const HomeCinemaSwitcher({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton("FILM", CinemaType.movies),
        const SizedBox(width: 25), // Spazio centrale
        _buildButton("SERIE TV", CinemaType.tvSeries),
      ],
    );
  }

  Widget _buildButton(String label, CinemaType type) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onTypeChanged(type),
      // Usa un Container trasparente per aumentare l'area di tocco
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            // La lineetta animata sotto (Stile TikTok)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 3,
              width: isSelected ? 20 : 0, // Si allarga se selezionato
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
