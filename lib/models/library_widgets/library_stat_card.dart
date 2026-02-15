import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/models/app_mode.dart';
// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';

class LibraryStatCard extends StatelessWidget {
  final String label;
  final String status;
  final IconData icon;
  final Color accentColor;
  final AppMode mode; // Fondamentale per sapere quale DB interrogare

  const LibraryStatCard({
    super.key,
    required this.label,
    required this.status,
    required this.icon,
    required this.accentColor,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) return _buildVisuals("0");

        // SELEZIONE STREAM DINAMICA
        // Qui avviene la magia: decidiamo quale UseCase chiamare
        Stream<List<dynamic>> countStream;
        if (mode == AppMode.books) {
          countStream = sl<GetUserBooksUseCase>().call(user.id, status);
        } else {
          countStream = sl<GetWatchlistUseCase>().call(user.id, status);
        }

        return StreamBuilder<List<dynamic>>(
          stream: countStream,
          builder: (context, snapshot) {
            final count = snapshot.hasData
                ? snapshot.data!.length.toString()
                : "0";
            return _buildVisuals(count);
          },
        );
      },
    );
  }

  Widget _buildVisuals(String count) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Grigio Scuro Matte
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withOpacity(0.2), // Bordo colorato sottile
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            // Glow interno sottile
            BoxShadow(
              color: accentColor.withOpacity(0.05),
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Icona Sfondo Gigante (Decorativa)
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                icon,
                size: 80,
                color: accentColor.withOpacity(0.05), // Molto tenue
              ),
            ),

            // 2. Contenuto
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icona piccola e Label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                // Il Numero Gigante
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.white.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    count,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
