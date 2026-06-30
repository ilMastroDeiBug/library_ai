import 'package:flutter/material.dart';
import '../../domain/entities/tv_series_progress.dart';

class StreakWidget extends StatelessWidget {
  final TvSeriesProgress progress;

  const StreakWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (!progress.isActive) return const SizedBox.shrink();

    final Color color = progress.isSafe ? Colors.white : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            '${progress.currentStreak}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
