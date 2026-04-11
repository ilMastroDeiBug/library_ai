import 'dart:math'; // <-- NECESSARIO PER IL RANDOMIZER
import 'package:flutter/material.dart';
import '../../services/pages_services/home_service.dart';
import '../../models/book_widgets/book_section.dart';
import '../../injection_container.dart';
import '../../models/ai_hero_banner.dart';
import '../../domain/entities/book.dart';
import '../../domain/use_cases/book_use_cases.dart';
import '../../domain/use_cases/movie_use_cases.dart';
import '../../domain/use_cases/tv_series_use_cases.dart';
import '../../pages/book_detail_page.dart';
import '../../pages/movie_detail_page.dart';
import '../../models/app_mode.dart';
import '../../models/movie_widget/movie_card.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';

class HomeContentBuilder {
  static List<Widget> buildBookContent() {
    return HomeService.bookSections.map((data) {
      if (data.containsKey('header')) {
        return _SectionHeader(text: data['header']);
      }
      return Column(
        children: [
          BookSection(title: data['title'], categoryQuery: data['query']),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }

  static List<Widget> buildCinemaContent({
    required CinemaType type,
    required Set<int> seenIds, // <-- RICEVE IL REGISTRO
  }) {
    final sections = (type == CinemaType.movies)
        ? HomeService.movieSections
        : HomeService.tvSections;
    return sections.map((section) {
      if (section.containsKey('header')) {
        return _SectionHeader(text: section['header']);
      }
      return CinemaHorizontalList(
        title: section['title'],
        path: section['path'],
        isTv: type == CinemaType.tvSeries,
        seenIds: seenIds, // <-- LO PASSA ALLA SINGOLA RIGA
      );
    }).toList();
  }

  static Widget buildHeroBanner(
    AppMode mode, {
    CinemaType cinemaType = CinemaType.movies,
    Set<int>? seenIds, // <-- RICEVE IL REGISTRO
  }) {
    return FutureBuilder<List<dynamic>>(
      key: ValueKey('hero_${mode.index}_${cinemaType.index}'),
      future: _fetchHeroItems(mode, cinemaType, seenIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 350,
            child: Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
          );
        }
        final heroItems = snapshot.data ?? [];
        if (heroItems.isEmpty) return const SizedBox(height: 350);
        return AiHeroBanner(
          items: heroItems.take(5).toList(),
          onItemTap: (item) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => item is Book
                    ? BookDetailPage(book: item)
                    : MovieDetailPage(media: item),
              ),
            );
          },
        );
      },
    );
  }

  static Future<List<dynamic>> _fetchHeroItems(
    AppMode mode,
    CinemaType cinemaType,
    Set<int>? seenIds,
  ) async {
    try {
      List<dynamic> items = [];
      if (mode == AppMode.books) {
        items = await sl<GetBooksByCategoryUseCase>().call("Fantasy");
      } else {
        items = cinemaType == CinemaType.movies
            ? await sl<GetMoviesByCategoryUseCase>().call("trending")
            : await sl<GetTvSeriesByCategoryUseCase>().call("trending");
      }

      // PRENOTAZIONE: Se ci sono film nel banner, li registriamo subito
      // così non appariranno nelle liste sottostanti!
      if (seenIds != null && items.isNotEmpty) {
        for (var item in items.take(5)) {
          seenIds.add(item.id);
        }
      }

      return items;
    } catch (e) {
      return [];
    }
  }
}

// -------------------------------------------------------------
// ORA È UNO STATEFUL WIDGET PER NON SPARE CHIAMATE API INUTILI
// E GESTIRE IL FILTRO DEI DOPPIONI
// -------------------------------------------------------------
class CinemaHorizontalList extends StatefulWidget {
  final String title;
  final String path;
  final bool isTv;
  final Set<int> seenIds;

  const CinemaHorizontalList({
    required this.title,
    required this.path,
    required this.isTv,
    required this.seenIds,
    super.key,
  });

  @override
  State<CinemaHorizontalList> createState() => _CinemaHorizontalListState();
}

class _CinemaHorizontalListState extends State<CinemaHorizontalList> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    // Spariamo il razzo una volta sola!
    _future = _fetchAndFilter();
  }

  Future<List<dynamic>> _fetchAndFilter() async {
    // 1. RANDOMIZER
    int pageToFetch = 1;
    if (widget.path.contains('with_genres=')) {
      pageToFetch = Random().nextInt(3) + 1;
    }

    // 2. FETCH SEPARATO (Evitiamo il conflitto di tipi di Dart!)
    List<dynamic> rawItems = [];
    if (widget.isTv) {
      rawItems = await sl<GetTvSeriesByCategoryUseCase>().call(
        widget.path,
        page: pageToFetch,
      );
    } else {
      rawItems = await sl<GetMoviesByCategoryUseCase>().call(
        widget.path,
        page: pageToFetch,
      );
    }

    // 3. DEDUPLICAZIONE ANTI-CLONI
    List<dynamic> uniqueItems = [];
    for (var item in rawItems) {
      // TYPE CHECKING: Estraiamo l'id in modo 100% sicuro
      int currentId = 0;
      if (item is Movie) {
        currentId = item.id;
      } else if (item is TvSeries) {
        currentId = item.id;
      } else {
        continue; // Fallback di sicurezza se l'item è rotto
      }

      // Se il set NON contiene l'id, il film/serie è inedito
      if (!widget.seenIds.contains(currentId)) {
        uniqueItems.add(item);
        widget.seenIds.add(currentId); // Lo blocchiamo per le righe future
      }
    }

    // 4. SHUFFLE
    if (widget.path.contains('with_genres=')) {
      uniqueItems.shuffle();
    }

    return uniqueItems;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title, // <-- Aggiornato a widget.title
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<dynamic>>(
            key: ValueKey('list_${widget.title}_${widget.isTv}'),
            future: _future, // <-- ORA USA IL FUTURE INIZIALIZZATO IN INITSTATE
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final items = snapshot.data ?? [];

              // Se la deduplicazione ha svuotato la lista, nascondiamo la riga gracefully
              if (items.isEmpty) return const SizedBox.shrink();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: MovieCard(
                      media: items[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailPage(media: items[index]),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 15),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.orangeAccent.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}
