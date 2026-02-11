import 'package:flutter/material.dart';
import '../models/book_model.dart';
// Importiamo il TUO Service specifico
import 'package:library_ai/services/utility_services/open_library_service.dart';
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
  final OpenLibraryService _booksService = OpenLibraryService();

  @override
  void initState() {
    super.initState();
    // Chiamiamo la tua funzione "Elite"
    _booksFuture = _booksService.fetchBooks(widget.categoryQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
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
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.white.withOpacity(0.3),
              ),
            ],
          ),
        ),

        // --- LISTA ORIZZONTALE ---
        SizedBox(
          height: 240, // Altezza calibrata per le BookCard
          child: FutureBuilder<List<Book>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              // 1. CARICAMENTO
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.cyanAccent,
                    strokeWidth: 2,
                  ),
                );
              }
              // 2. NESSUN DATO o ERRORE (Il tuo service ritorna [] se fallisce)
              else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white.withOpacity(0.2),
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Nessun top book trovato.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 3. SUCCESSO (Lista Elite pronta)
              final books = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 10),
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
