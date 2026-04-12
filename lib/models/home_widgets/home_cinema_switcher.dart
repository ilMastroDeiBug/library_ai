import 'package:flutter/material.dart';
import '../app_mode.dart';

class HomeCinemaSwitcher extends StatelessWidget {
  final CinemaType selectedType;
  final ValueChanged<CinemaType> onTypeChanged;

  const HomeCinemaSwitcher({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTab(context, "Film", CinemaType.movies),
        const SizedBox(width: 25),
        _buildTab(context, "Serie TV", CinemaType.tvSeries),
      ],
    );
  }

  Widget _buildTab(BuildContext context, String text, CinemaType type) {
    final isActive = selectedType == type;

    return GestureDetector(
      onTap: () => onTypeChanged(type),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TESTO ANIMATO
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: isActive ? 18 : 16,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 0.5,
              shadows: isActive
                  ? [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Text(text),
          ),
          const SizedBox(height: 4),
          // TRATTINO SOTTOSTANTE ANIMATO
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 3,
            width: isActive ? 20 : 0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
