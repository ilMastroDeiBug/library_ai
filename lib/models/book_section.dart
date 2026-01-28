import 'package:flutter/material.dart';
import '../models/book_model.dart';
// FIX IMPORT: Usiamo il percorso relativo per sicurezza massima
import '../services/google_books_service.dart';
import 'book_card.dart';

class BookSection extends StatefulWidget {
  final String title;
  final String categoryQuery;

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
    // Carichiamo i libri all'avvio del widget
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Icona freccia decorativa
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),

        // Lista Orizzontale
        SizedBox(
          height: 220, // Altezza ottimizzata per la card
          child: FutureBuilder<List<Book>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                );
              } else if (snapshot.hasError) {
                // Mostra l'errore a video se c'è
                return Center(
                  child: Text(
                    "Errore: ${snapshot.error}",
                    style: TextStyle(color: Colors.red.withOpacity(0.7)),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "Nessun libro trovato per '${widget.categoryQuery}'",
                    style: TextStyle(color: Colors.white.withOpacity(0.3)),
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
