import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/entities/book.dart'; // O domain/entities/book.dart
import '/models/book_widgets/book_card.dart';

class GenreResultPage extends StatefulWidget {
  final String categoryName;
  final String categoryId;

  const GenreResultPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<GenreResultPage> createState() => _GenreResultPageState();
}

class _GenreResultPageState extends State<GenreResultPage> {
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    // USE CASE
    _booksFuture = sl<GetBooksByCategoryUseCase>().call(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    // ... UI IDENTICA ...
    return Scaffold(
      backgroundColor: const Color(0xFF232526),
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF232526),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Errore: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nessun libro trovato",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final books = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) => BookCard(book: books[index]),
          );
        },
      ),
    );
  }
}
