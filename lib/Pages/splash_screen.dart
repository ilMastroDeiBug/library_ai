import 'package:flutter/material.dart';
import 'dart:async';
// RIMOSSO: import 'package:flutter_svg/flutter_svg.dart'; (Non serve più per JPG/PNG)
import '../main.dart';

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

    // Effetto respiro morbido
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _startTimer();
  }

  _startTimer() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
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
    // Leggiamo la larghezza dello schermo
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(
        0xFF0A0A0C,
      ), // Il nero/grigio scuro di sfondo
      body: Stack(
        children: [
          // 🖼️ LIVELLO 1: IL LOGO CENTRATO PROPORZIONALE
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.02).animate(_animation),
              child: SizedBox(
                // Usa il 60% della larghezza dello schermo
                width: screenWidth * 0.60,
                // FIX APPLICATO QUI: Usiamo Image.asset per leggere correttamente i JPG o PNG
                child: Image.asset(
                  'assets/images/cinelogo.jpg', // ATTENZIONE: Controlla che il nome sia esattamente questo
                  fit: BoxFit
                      .contain, // "Stai tutto dentro il SizedBox senza tagliarti"
                ),
              ),
            ),
          ),

          // 🌀 LIVELLO 2: IL LOADER IN BASSO
          Align(
            alignment: const Alignment(0, 0.8), // 80% verso il basso
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orangeAccent.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
