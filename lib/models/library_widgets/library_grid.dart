import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/pages_services/library_service.dart';
import '/models/book_widgets/book_model.dart';
import '/models/book_widgets/book_card.dart';
import '../app_mode.dart';
import 'delete_book_dialog.dart';

class LibraryGrid extends StatelessWidget {
  final AppMode mode;
  final String status;
  final LibraryService _service = LibraryService();

  LibraryGrid({super.key, required this.mode, required this.status});

  Future<void> _handleDelete(
    BuildContext context,
    String bookId,
    String title,
  ) async {
    // Mostra il dialog estratto
    showDialog(
      context: context,
      builder: (ctx) => DeleteBookDialog(
        bookTitle: title,
        onConfirm: () async {
          try {
            await _service.deleteBook(bookId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Dato rimosso dal database."),
                  backgroundColor: Colors.redAccent.withOpacity(0.8),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            // Gestione errore
            print(e);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBooks = mode == AppMode.books;

    if (!isBooks) return _buildMoviesPlaceholder();

    return Container(
      color: const Color(0xFF0F0F10),
      child: StreamBuilder<QuerySnapshot>(
        stream: _service.getUserBooksStream(status),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 20,
              mainAxisSpacing: 25,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bookId = docs[index].id;

              // Mapping sicuro
              final book = Book(
                id: bookId,
                title: data['title'] ?? 'N/D',
                author: data['author'] ?? 'Sconosciuto',
                thumbnailUrl: data['thumbnailUrl'] ?? '',
                description: data['description'] ?? '',
                pageCount: data['pageCount'],
                averageRating: (data['averageRating'] as num?)?.toDouble(),
                ratingsCount: data['ratingsCount'],
              );

              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onLongPress: () => _handleDelete(context, bookId, book.title),
                child: BookCard(book: book),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == 'toread'
                ? Icons.bookmark_add_outlined
                : Icons.done_all_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 15),
          Text(
            status == 'toread'
                ? "Database vuoto.\nAggiungi nuovi input."
                : "Nessun task completato.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.3), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            size: 60,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 15),
          Text(
            "Modulo Cinema in sviluppo...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
