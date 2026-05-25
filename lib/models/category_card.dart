import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../../models/app_mode.dart';
import '../Pages/genre_result_page.dart';

class CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final AppMode mode;
  final bool isTvSeries;

  const CategoryCard({
    super.key,
    required this.category,
    required this.mode,
    this.isTvSeries = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenreResultPage(
              category: category, // <-- ECCO IL FIX: Passiamo l'intero oggetto!
              mode: mode,
              isTvSeries: isTvSeries,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Text(
                  category.name,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
