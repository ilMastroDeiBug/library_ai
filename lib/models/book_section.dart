import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'package:library_ai/google_books_service.dart';
import 'book_card.dart';

class BookSection extends StatefulWidget {
  final String title;
  final String categoryQuery; // Es. "fantasy", "horror"

  const BookSection({
    super.key,
    required this.title,
    required this.categoryQuery,
  });

  @override
  State<BookSection> createState() => _BookSectionState();
}

class _BookSectionState extends State<BookSection> {
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    // Appena nasce il widget, lanciamo la richiesta a Google
    _booksFuture = GoogleBooksService().fetchBooksByCategory(
      widget.categoryQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo Sezione
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Lista Orizzontale Asincrona
        SizedBox(
          height: 260,
          child: FutureBuilder<List<Book>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text("Errore", style: TextStyle(color: Colors.red)),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "Nessun libro trovato",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final books = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return BookCard(book: books[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
