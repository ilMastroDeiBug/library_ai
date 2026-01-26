import 'package:flutter/material.dart';

class AppColors {
  static const gradientStart = Color(0xFF232526);
  static const gradientEnd = Color(0xFF414345);
  static const accent = Colors.cyanAccent;

  static const mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
}
