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

  static const Color _accentColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTab("FILM", CinemaType.movies),
            _buildTab("SERIE TV", CinemaType.tvSeries),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, CinemaType type) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _accentColor.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
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
