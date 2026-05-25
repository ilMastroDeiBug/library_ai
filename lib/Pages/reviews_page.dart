import 'package:flutter/material.dart';
import '../domain/entities/book.dart'; // O domain/entities/book.dart

class ReviewsPage extends StatelessWidget {
  final Book book;

  const ReviewsPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        title: Text(book.title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 20),
            const Text(
              "Recensioni della Community",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Qui appariranno le recensioni degli altri Architect. Work in progress...",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 30),
            // Qui metteremo il bottone per SCRIVERE la recensione
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: const Text("Scrivi la prima recensione"),
            ),
          ],
        ),
      ),
    );
  }
}
