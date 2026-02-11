import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../pages/genre_result_page.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenreResultPage(
              categoryName: category.name,
              categoryId: category.id,
            ),
          ),
        );
      },
      child: Container(
        // Decorazione Scura ed Elegante
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Sfondo Base Scuro
          borderRadius: BorderRadius.circular(20),
          // Bordo sottile colorato per dare l'accento
          border: Border.all(color: category.color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          // Gradiente interno molto sottile per dare volume
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)],
          ),
        ),
        // Clip per tagliare l'icona che sborda
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Icona Gigante Decorativa (Watermark)
            Positioned(
              right: -20,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.2, // Leggera inclinazione per dinamismo
                child: Icon(
                  category.icon,
                  size: 110,
                  // Usa il colore della categoria ma molto trasparente
                  color: category.color.withOpacity(0.08),
                ),
              ),
            ),

            // 2. Contenuto
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icona Piccola nel badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: category.color.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color, // Colore pieno (Ciano o Arancio)
                      size: 24,
                    ),
                  ),

                  // Nome Categoria
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      // Freccettina decorativa
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ],
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
