import 'package:flutter/material.dart';
import '../domain/entities/book.dart'; // O domain/entities/book.dart

class ReviewsPage extends StatelessWidget {
  final Book book;

  const ReviewsPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(book.title, style: const TextStyle(fontSize: 16)),
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
            Text(
              "Recensioni della Community",
              style: TextStyle(
                color: Colors.cyanAccent.withOpacity(0.8),
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
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
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
