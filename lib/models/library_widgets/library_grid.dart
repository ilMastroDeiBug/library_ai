import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/models/app_mode.dart';

// Entities
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart'; // Importa TvSeries

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
        if (user == null) {
          return const Center(
            child: Text(
              "Accesso richiesto",
              style: TextStyle(color: Colors.white24),
            ),
          );
        }

        // Recuperiamo lo stream. Per i Film/Serie usiamo GetWatchlistUseCase
        // che restituisce una lista mista di Movie e TvSeries
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 15,
                mainAxisSpacing: 20,
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
    String title = "";
    String imageUrl = "";
    String heroTag = "";

    // GESTIONE POLIMORFICA COMPLETA
    if (item is Book) {
      title = item.title;
      imageUrl = item.thumbnailUrl;
      heroTag = item.id;
    } else if (item is Movie) {
      title = item.title;
      imageUrl = item.fullPosterUrl;
      heroTag = item.id.toString();
    } else if (item is TvSeries) {
      title = item.name; // TvSeries usa 'name'
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
                : MovieDetailPage(media: item), // Accetta anche TvSeries
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag: heroTag,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            "ARCHIVIO VUOTO",
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
