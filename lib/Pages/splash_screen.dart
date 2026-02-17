import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart'; // Importa il main per accedere ad AuthGate

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animazione (Effetto Respiro/Pulsazione)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 2. Avvia il Timer
    _startTimer();
  }

  _startTimer() async {
    // Aspettiamo 3 secondi per godersi il logo e caricare i servizi in background
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 3. PASSA LA PALLA AL PORTIERE (AuthGate)
    // Usiamo pushReplacement per non poter tornare indietro alla splash
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthGate()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Sfondo Dark
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Animato
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(_animation),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories, // La tua icona
                  size: 80,
                  color: Colors.cyanAccent,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Testo "Architect" style
            FadeTransition(
              opacity: _animation,
              child: const Text(
                "LIBRARY AI",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "NEURAL NEXUS",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
