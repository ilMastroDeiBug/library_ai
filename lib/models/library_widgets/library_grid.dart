import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/models/app_mode.dart';

// Entities
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';

// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';

// Pages
import 'package:library_ai/Pages/book_detail_page.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';

class LibraryGrid extends StatelessWidget {
  final AppMode mode;
  final String status;

  const LibraryGrid({super.key, required this.mode, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) return const SizedBox.shrink();

        final dynamic dataStream = (mode == AppMode.books)
            ? sl<GetUserBooksUseCase>().call(user.id, status)
            : sl<GetWatchlistUseCase>().call(user.id, status);

        return StreamBuilder<List<dynamic>>(
          stream: dataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return _buildEmptyState();
            }

            return GridView.builder(
              // Padding che si fonde col bordo nero del telefono
              padding: const EdgeInsets.only(
                top: 20,
                left: 15,
                right: 15,
                bottom: 120,
              ),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 Colonne Stile Netflix!
                childAspectRatio: 0.68, // Proporzione esatta della locandina
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemCard(context, item);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, dynamic item) {
    String imageUrl = "";
    String heroTag = "";

    if (item is Book) {
      imageUrl = item.thumbnailUrl;
      heroTag = item.id;
    } else if (item is Movie) {
      imageUrl = item.fullPosterUrl;
      heroTag = item.id.toString();
    } else if (item is TvSeries) {
      imageUrl = item.fullPosterUrl;
      heroTag = item.id.toString();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => (item is Book)
                ? BookDetailPage(book: item)
                : MovieDetailPage(media: item),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(
              8,
            ), // Curvatura stretta ed elegante
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          // Se per caso manca l'immagine, mostriamo un'icona centrata
          child: imageUrl.isEmpty
              ? Icon(
                  mode == AppMode.books ? Icons.book : Icons.movie,
                  color: Colors.white24,
                  size: 30,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            mode == AppMode.books
                ? Icons.auto_stories
                : Icons.movie_filter_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            "NESSUN ELEMENTO",
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              letterSpacing: 2.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
