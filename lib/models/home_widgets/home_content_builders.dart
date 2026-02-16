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
  static List<Widget> buildBookContent() {
    return HomeService.bookSections.map((data) {
      if (data.containsKey('header'))
        return _SectionHeader(text: data['header']);
      return Column(
        children: [
          BookSection(title: data['title'], categoryQuery: data['query']),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }

  static List<Widget> buildCinemaContent({required CinemaType type}) {
    final sections = (type == CinemaType.movies)
        ? HomeService.movieSections
        : HomeService.tvSections;
    return sections.map((section) {
      if (section.containsKey('header'))
        return _SectionHeader(text: section['header']);
      return CinemaHorizontalList(
        title: section['title'],
        path: section['path'],
        isTv: type == CinemaType.tvSeries,
      );
    }).toList();
  }

  static Widget buildHeroBanner(
    AppMode mode, {
    CinemaType cinemaType = CinemaType.movies,
  }) {
    return FutureBuilder<List<dynamic>>(
      key: ValueKey('hero_${mode.index}_${cinemaType.index}'),
      future: _fetchHeroItems(mode, cinemaType),
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
  ) async {
    try {
      if (mode == AppMode.books)
        return await sl<GetBooksByCategoryUseCase>().call("Fantasy");
      return cinemaType == CinemaType.movies
          ? await sl<GetMoviesByCategoryUseCase>().call("trending")
          : await sl<GetTvSeriesByCategoryUseCase>().call("trending");
    } catch (e) {
      return [];
    }
  }
}

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
    final future = isTv
        ? sl<GetTvSeriesByCategoryUseCase>().call(path)
        : sl<GetMoviesByCategoryUseCase>().call(path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
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
            key: ValueKey('list_${title}_${isTv}'),
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final items = snapshot.data ?? [];
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
