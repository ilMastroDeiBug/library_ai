import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo con effetto Glow
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: Colors.cyanAccent.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.auto_stories,
            size: 70,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(height: 40),

        // Titolo stilizzato
        const Text(
          "LIBRARY AI",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(2, 2),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Eleva la tua conoscenza.",
          style: TextStyle(
            color: Colors.cyanAccent.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
