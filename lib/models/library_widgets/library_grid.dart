import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/models/app_mode.dart';

// Entities
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/entities/favorite_item.dart';

// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart';

// Pages
import 'package:library_ai/Pages/book_detail_page.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';
import 'package:library_ai/Pages/actor_detail_page.dart';

class LibraryGrid extends StatefulWidget {
  final AppMode mode;
  final String status;

  const LibraryGrid({super.key, required this.mode, required this.status});

  @override
  State<LibraryGrid> createState() => _LibraryGridState();
}

class _LibraryGridState extends State<LibraryGrid> {
  // Stato locale per Ricerca e Filtri
  String _searchQuery = "";
  String _selectedFilter = "Tutti";

  // Determina quali filtri mostrare in base alla tab in cui ci troviamo
  List<String> get _availableFilters {
    if (widget.mode == AppMode.books) return ['Tutti']; // Per i libri in futuro
    if (widget.status == 'favorites') {
      return ['Tutti', 'Film', 'Serie TV', 'Attori'];
    }
    return ['Tutti', 'Film', 'Serie TV'];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) return const SizedBox.shrink();

        // 1. SELEZIONIAMO LO STREAM GIUSTO
        final dynamic dataStream;
        if (widget.status == 'favorites') {
          final filterType = widget.mode == AppMode.books ? 'book' : null;
          dataStream = sl<GetFavoritesStreamUseCase>().call(
            user.id,
            type: filterType,
          );
        } else if (widget.mode == AppMode.books) {
          dataStream = sl<GetUserBooksUseCase>().call(user.id, widget.status);
        } else {
          dataStream = sl<GetWatchlistUseCase>().call(user.id, widget.status);
        }

        return Column(
          children: [
            // --- HEADER RICERCA E FILTRI ---
            _buildSearchAndFilterHeader(),

            // --- GRIGLIA RISULTATI ---
            Expanded(
              child: StreamBuilder<List<dynamic>>(
                stream: dataStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orangeAccent,
                      ),
                    );
                  }

                  final allItems = snapshot.data ?? [];

                  // 2. APPLICHIAMO FILTRI E RICERCA LOCALMENTE
                  final filteredItems = _applyLocalFilters(allItems);

                  if (filteredItems.isEmpty) {
                    return _buildEmptyState();
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(
                      top: 10, // Ridotto perché c'è già l'header sopra
                      left: 15,
                      right: 15,
                      bottom: 120,
                    ),
                    itemCount: filteredItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildItemCard(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- LOGICA DI FILTRAGGIO IN-PLACE ---
  List<dynamic> _applyLocalFilters(List<dynamic> items) {
    return items.where((item) {
      // Estraiamo il titolo per la ricerca testuale
      String title = '';
      if (item is Book)
        title = item.title;
      else if (item is Movie)
        title = item.title;
      else if (item is TvSeries)
        title = item.name;
      else if (item is FavoriteItem)
        title = item.title;

      // Filtro 1: Barra di Ricerca
      if (_searchQuery.isNotEmpty &&
          !title.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      // Filtro 2: Chip (Film, Serie TV, Attori)
      if (_selectedFilter != 'Tutti') {
        if (_selectedFilter == 'Film') {
          if (item is! Movie &&
              !(item is FavoriteItem && item.itemType == 'movie'))
            return false;
        } else if (_selectedFilter == 'Serie TV') {
          if (item is! TvSeries &&
              !(item is FavoriteItem && item.itemType == 'tv'))
            return false;
        } else if (_selectedFilter == 'Attori') {
          if (!(item is FavoriteItem && item.itemType == 'person'))
            return false;
        }
      }

      return true; // Se passa tutti i controlli, mostralo!
    }).toList();
  }

  // --- UI HEADER (BARRA E CHIP) ---
  Widget _buildSearchAndFilterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
      child: Column(
        children: [
          // Barra di Ricerca
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cerca nella lista...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white54,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Chips dei Filtri (Scrollabili Orizzontalmente)
          if (_availableFilters.length > 1)
            SizedBox(
              height: 35,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _availableFilters.length,
                itemBuilder: (context, index) {
                  final filter = _availableFilters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.orangeAccent,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      side: BorderSide.none,
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --- UI CARD E NAVIGAZIONE (Invariato dall'ultima versione con i Gradienti) ---
  Widget _buildItemCard(BuildContext context, dynamic item) {
    String imageUrl = "";
    String heroTag = "";
    String overlayName = "";

    if (item is Book) {
      imageUrl = item.thumbnailUrl;
      heroTag = item.id;
      overlayName = item.title;
    } else if (item is Movie) {
      imageUrl = item.fullPosterUrl;
      heroTag = item.id.toString();
      overlayName = item.title;
    } else if (item is TvSeries) {
      imageUrl = item.fullPosterUrl;
      heroTag = item.id.toString();
      overlayName = item.name;
    } else if (item is FavoriteItem) {
      imageUrl = item.posterUrl ?? '';
      heroTag = 'fav_${item.itemType}_${item.itemId}';
      overlayName = item.title;
    }

    return GestureDetector(
      onTap: () {
        if (item is FavoriteItem) {
          if (item.itemType == 'person') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActorDetailPage(actorId: item.itemId),
              ),
            );
            return;
          }

          final bool isFullUrl =
              item.posterUrl != null && item.posterUrl!.startsWith('http');
          final String barePath = isFullUrl
              ? item.posterUrl!.replaceAll(
                  RegExp(r'https://image\.tmdb\.org/t/p/w\d+'),
                  '',
                )
              : (item.posterUrl ?? '');

          dynamic stubMedia;
          if (item.itemType == 'movie') {
            stubMedia = Movie(
              id: item.itemId,
              title: item.title,
              overview: 'Dettagli base dai preferiti.',
              posterPath: barePath,
              backdropPath: barePath,
              voteAverage: 0.0,
              voteCount: 0,
              releaseDate: '',
              popularity: 0.0,
              status: 'none',
            );
          } else {
            stubMedia = TvSeries(
              id: item.itemId,
              name: item.title,
              overview: 'Dettagli base dai preferiti.',
              posterPath: barePath,
              backdropPath: barePath,
              voteAverage: 0.0,
              voteCount: 0,
              firstAirDate: '',
              popularity: 0.0,
              status: 'none',
            );
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailPage(media: stubMedia),
            ),
          );
          return;
        }

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
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(
                        widget.mode == AppMode.books
                            ? Icons.book
                            : Icons.movie,
                        color: Colors.white24,
                        size: 30,
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Icon(
                    widget.mode == AppMode.books ? Icons.book : Icons.movie,
                    color: Colors.white24,
                    size: 30,
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 25,
                    bottom: 8,
                    left: 6,
                    right: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: Text(
                    overlayName.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            widget.mode == AppMode.books
                ? Icons.auto_stories
                : Icons.movie_filter_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "NESSUN RISULTATO" // Cambio testuale dinamico se l'utente cerca qualcosa che non c'è
                : (widget.status == 'favorites'
                      ? "NESSUN PREFERITO"
                      : "NESSUN ELEMENTO"),
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
