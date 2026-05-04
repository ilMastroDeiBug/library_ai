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
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';
import '../../services/utility_services/language_service.dart';
import 'cinema_horizontal.dart'; // Assicurati che l'import sia corretto per CinemaHorizontalList

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
    required Set<int> seenIds,
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
        seenIds: seenIds,
      );
    }).toList();
  }

  static Widget buildHeroBanner(
    AppMode mode, {
    CinemaType cinemaType = CinemaType.movies,
    Set<int>? seenIds,
  }) {
    final languageCode = sl<LanguageService>().currentLanguage;

    return StreamBuilder<List<dynamic>>(
      key: ValueKey('hero_${mode.index}_${cinemaType.index}_$languageCode'),
      stream: _heroItemsStream(mode, cinemaType, seenIds),
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

  static Stream<List<dynamic>> _heroItemsStream(
    AppMode mode,
    CinemaType cinemaType,
    Set<int>? seenIds,
  ) async* {
    try {
      if (mode == AppMode.books) {
        // I libri sono rimasti dei Future
        final books = await sl<GetBooksByCategoryUseCase>().call("Fantasy");
        yield List<dynamic>.from(books);
        return;
      }

      // Risolto il problema del cast dinamico
      final Stream<List<dynamic>> stream = cinemaType == CinemaType.movies
          ? sl<GetMoviesByCategoryUseCase>()
                .call("trending")
                .map((items) => List<dynamic>.from(items))
          : sl<GetTvSeriesByCategoryUseCase>()
                .call("trending")
                .map((items) => List<dynamic>.from(items));

      await for (final items in stream) {
        if (seenIds != null && items.isNotEmpty) {
          for (var item in items.take(5)) {
            // Controllo sicuro prima di accedere all'ID
            if (item is Movie) seenIds.add(item.id);
            if (item is TvSeries) seenIds.add(item.id);
          }
        }
        yield items;
      }
    } catch (e) {
      yield [];
    }
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
