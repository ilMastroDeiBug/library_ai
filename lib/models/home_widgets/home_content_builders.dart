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

class HomeContentBuilder {
  // --- LIBRI ---
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

  // --- CINEMA ---
  static List<Widget> buildCinemaContent({required CinemaType type}) {
    // Sceglie la lista in base allo switcher
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
        isTv:
            type ==
            CinemaType.tvSeries, // FIX: Usato tvShows per matchare l'enum
      );
    }).toList();
  }

  // --- HERO BANNER ---
  static Widget buildHeroBanner(
    AppMode mode, {
    CinemaType cinemaType = CinemaType.movies,
  }) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchHeroItems(mode, cinemaType),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 280,
            child: Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
          );
        }
        final heroItems = snapshot.data!.take(5).toList();
        return AiHeroBanner(
          items: heroItems,
          onItemTap: (item) {
            if (item is Book) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailPage(book: item)),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MovieDetailPage(media: item)),
              );
            }
          },
        );
      },
    );
  }

  static Future<List<dynamic>> _fetchHeroItems(
    AppMode mode,
    CinemaType cinemaType,
  ) async {
    try {
      if (mode == AppMode.books) {
        return await sl<GetBooksByCategoryUseCase>().call("Fantasy");
      } else {
        return cinemaType == CinemaType.movies
            ? await sl<GetMoviesByCategoryUseCase>().call("trending")
            : await sl<GetTvSeriesByCategoryUseCase>().call("trending");
      }
    } catch (e) {
      return [];
    }
  }
}

// --- WIDGET LISTA ORIZZONTALE CINEMA ---
class CinemaHorizontalList extends StatelessWidget {
  final String title;
  final String path;
  final bool isTv;

  const CinemaHorizontalList({
    required this.title,
    required this.path,
    required this.isTv,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<dynamic>>(
            future: isTv
                ? sl<GetTvSeriesByCategoryUseCase>().call(path)
                : sl<GetMoviesByCategoryUseCase>().call(path),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const SizedBox.shrink();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  return MovieCard(
                    media: item,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailPage(media: item),
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
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.orangeAccent.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
