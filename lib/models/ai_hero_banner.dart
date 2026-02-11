import 'package:flutter/material.dart';

class AIHeroBanner extends StatelessWidget {
  const AIHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepPurpleAccent, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Sfondo decorativo (Icona gigante semi-trasparente)
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.auto_stories,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Contenuto Testuale
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge "Consigliato"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "CONSIGLIATO DALL'AI",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Titolo Libro (Statico per ora)
                  const Text(
                    "L'Arte della Guerra",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Autore
                  const Text(
                    "Sun Tzu",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
