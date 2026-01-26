import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String count;
  final String label;

  const StatCard({super.key, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.cyanAccent, // O usa AppColors.accent
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}
