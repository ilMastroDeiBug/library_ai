import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../../models/app_mode.dart';
import '../Pages/genre_result_page.dart'; // <-- Assicurati che il percorso sia corretto (la cartella Pages di solito ha la P maiuscola nel tuo progetto)

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
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -15,
              child: Text(
                category.name
                    .substring(
                      0,
                      category.name.length > 3 ? 4 : category.name.length,
                    )
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.03),
                  letterSpacing: -5,
                ),
              ),
            ),

            Positioned(
              left: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orangeAccent.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      blurRadius: 40,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.orangeAccent,
                      size: 26,
                    ),
                  ),
                  Text(
                    category.name,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
