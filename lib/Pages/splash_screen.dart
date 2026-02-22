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

    // 1. Setup Animazione (Effetto Respiro/Pulsazione del logo)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 2. Avvia il Timer
    _startTimer();
  }

  _startTimer() async {
    // Aspettiamo 3 secondi per godersi il logo e caricare Firebase
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 3. PASSA LA PALLA AL PORTIERE (AuthGate)
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
      backgroundColor: const Color(
        0xFF0A0A0C,
      ), // Sfondo Dark che matcha il tuo logo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IL TUO VERO LOGO ANIMATO
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.05).animate(_animation),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(
                        0.15,
                      ), // Glow arancione
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Arrotondiamo un po' i bordi del jpg
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200, // Grandezza del logo
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Un piccolo loader elegante sotto il logo
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orangeAccent.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
