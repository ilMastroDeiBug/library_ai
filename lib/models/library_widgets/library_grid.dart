import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../../domain/entities/book.dart';
import '/models/book_widgets/book_card.dart';
import '../app_mode.dart';
import 'delete_book_dialog.dart';

class LibraryGrid extends StatelessWidget {
  final AppMode mode;
  final String status;

  const LibraryGrid({super.key, required this.mode, required this.status});

  Future<void> _handleDelete(
    BuildContext context,
    String bookId,
    String title,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => DeleteBookDialog(
        bookTitle: title,
        onConfirm: () async {
          try {
            // USE CASE: DELETE
            await sl<DeleteBookUseCase>().call(bookId);

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

    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) return _buildEmptyState();

        return Container(
          color: const Color(0xFF0F0F10),
          child: StreamBuilder<List<Book>>(
            stream: sl<GetUserBooksUseCase>().call(user.id, status),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final books = snapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                itemCount: books.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 25,
                ),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onLongPress: () => _handleDelete(context, book.id, book.title),
                    child: BookCard(book: book),
                  );
                },
              );
            },
          ),
        );
      },
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
    return const Center(
      child: Text(
        "Sezione Cinema in arrivo...",
        style: TextStyle(color: Colors.white30),
      ),
    );
  }
}
