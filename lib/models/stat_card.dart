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
            color: Colors.cyanAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5), // GRIGIO ELEGANTE
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
