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
import 'cinema_horizontal.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class HomeContentBuilder {
  static List<Widget> buildBookContent(BuildContext context) {
    return HomeService.bookSections.map((data) {
      if (data.containsKey('header')) {
        return _SectionHeader(text: _translateHomeString(context, data['header']));
      }
      return Column(
        children: [
          BookSection(
            title: _translateHomeString(context, data['title'] ?? ''),
            categoryQuery: data['query'],
          ),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }

  static String _translateHomeString(BuildContext context, String original) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return original;

    switch (original) {
      // Headers
      case 'NARRATIVA':
        return l10n.homeHeaderFiction;
      case 'CONOSCENZA & SVILUPPO':
        return l10n.homeHeaderKnowledge;
      case 'ALTRI INTERESSI':
        return l10n.homeHeaderOtherInterests;
      case 'FILM IN EVIDENZA':
        return l10n.homeHeaderFeaturedMovies;
      case 'AZIONE & ADRENALINA':
        return l10n.homeHeaderAction;
      case 'SENTIMENTO & STORIA':
        return l10n.homeHeaderDrama;
      case 'FANTASTICO & DARK':
        return l10n.homeHeaderFantasy;
      case 'INTRATTENIMENTO':
        return l10n.homeHeaderEntertainment;
      case 'SERIE TV IN EVIDENZA':
        return l10n.homeHeaderFeaturedTv;
      case 'SENSE OF WONDER':
        return l10n.homeHeaderWonder;
      case 'DRAMMA & TENSIONE':
        return l10n.homeHeaderTvDrama;
      case 'INTRATTENIMENTO TV':
        return l10n.homeHeaderTvEntertainment;

      // Titles (Books)
      case 'Bestsellers & Classici':
        return l10n.homeTitleBestsellers;
      case 'Thriller & Suspense':
        return l10n.homeTitleThriller;
      case 'Sci-Fi & Cyberpunk':
        return l10n.homeTitleSciFi;
      case 'Fantasy Epico':
        return l10n.homeTitleFantasyEpico;
      case 'Avventura':
        return l10n.homeTitleAdventure;
      case 'Romance & Love Stories':
        return l10n.homeTitleRomance;
      case 'Horror & Dark':
        return l10n.homeTitleHorror;
      case 'Gialli & Mistery':
        return l10n.homeTitleMystery;
      case 'Romanzi Storici':
        return l10n.homeTitleHistoricalFiction;
      case 'Mindset & Crescita':
        return l10n.homeTitleMindset;
      case 'Business & Finanza':
        return l10n.homeTitleBusiness;
      case 'Psicologia':
        return l10n.homeTitlePsychology;
      case 'Filosofia':
        return l10n.homeTitlePhilosophy;
      case 'Scienza & Tecnologia':
        return l10n.homeTitleScience;
      case 'Storia':
        return l10n.homeTitleHistory;
      case 'Biografie':
        return l10n.homeTitleBiography;
      case 'Arte & Design':
        return l10n.homeTitleArtDesign;
      case 'Graphic Novels & Manga':
        return l10n.homeTitleGraphicManga;
      case 'Cucina & Food':
        return l10n.homeTitleCooking;
      case 'Viaggi':
        return l10n.homeTitleTravel;

      // Titles (Cinema/TV)
      case 'Al Cinema ora':
        return l10n.inTheatersNow;
      case 'Più Popolari':
        return l10n.mostPopular;
      case 'Grandi Successi (Top)':
        return l10n.topRated;
      case 'Prossime Uscite':
        return l10n.upcoming;
      case 'Trend della Settimana':
      case 'Trending della Settimana':
        return l10n.trending;
      case 'In onda Oggi':
        return l10n.airingToday;
      case 'Novità in arrivo':
        return l10n.onTheAir;
      case 'Le Migliori di sempre':
        return l10n.bestOfAllTime;

      // Genres (Cinema/TV)
      case 'Azione':
        return l10n.homeTitleAction;
      case 'Thriller':
        return l10n.homeTitleThriller;
      case 'Crime':
        return l10n.homeTitleCrime;
      case 'Guerra':
        return l10n.homeTitleWar;
      case 'Drammatico':
        return l10n.homeTitleDrama;
      case 'Romantico':
        return l10n.homeTitleRomance;
      case 'Storico':
        return l10n.homeTitleHistory;
      case 'Western':
        return l10n.homeTitleWestern;
      case 'Fantasy':
        return l10n.homeTitleFantasyEpico;
      case 'Horror':
        return l10n.homeTitleHorror;
      case 'Mistero':
        return l10n.homeTitleMystery;
      case 'Animazione':
        return l10n.homeTitleAnimation;
      case 'Commedia':
        return l10n.homeTitleComedy;
      case 'Per la Famiglia':
        return l10n.homeTitleFamily;
      case 'Musica':
        return l10n.homeTitleMusic;
      case 'Documentari':
        return l10n.homeTitleDocumentaries;
      case 'Sci-Fi & Fantasy':
        return l10n.homeTitleSciFiFantasy;
      case 'Action & Adventure':
        return l10n.homeTitleActionAdventure;
      case 'Guerra & Politica':
        return l10n.homeTitleWarPolitics;
      case 'Soap Opera':
        return l10n.homeTitleSoap;
      case 'Kids':
        return l10n.homeTitleKids;
      case 'Reality & Talk':
        return l10n.homeTitleRealityTalk;

      default:
        return original;
    }
  }

  static List<Widget> buildCinemaContent(
    BuildContext context, {
    required CinemaType type,
    required Set<int> seenIds,
  }) {
    final sections =
        (type == CinemaType.movies)
            ? HomeService.movieSections
            : HomeService.tvSections;
    return sections.map((section) {
      if (section.containsKey('header')) {
        return _SectionHeader(text: _translateHomeString(context, section['header']));
      }
      return CinemaHorizontalList(
        title: _translateHomeString(context, section['title'] ?? ''),
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
    return _HeroBannerWrapper(
      mode: mode,
      cinemaType: cinemaType,
      seenIds: seenIds,
    );
  }

  static Stream<List<dynamic>> _heroItemsStream(
    AppMode mode,
    CinemaType cinemaType,
    Set<int>? seenIds,
  ) async* {
    try {
      if (mode == AppMode.books) {
        final books = await sl<GetBooksByCategoryUseCase>().call("Fantasy");
        yield List<dynamic>.from(books);
        return;
      }

      final Stream<List<dynamic>> stream =
          cinemaType == CinemaType.movies
              ? sl<GetMoviesByCategoryUseCase>().call("trending").map(
                (items) => List<dynamic>.from(items),
              )
              : sl<GetTvSeriesByCategoryUseCase>().call("trending").map(
                (items) => List<dynamic>.from(items),
              );

      await for (final items in stream) {
        if (seenIds != null && items.isNotEmpty) {
          for (var item in items.take(5)) {
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

class _HeroBannerWrapper extends StatefulWidget {
  final AppMode mode;
  final CinemaType cinemaType;
  final Set<int>? seenIds;

  const _HeroBannerWrapper({
    required this.mode,
    required this.cinemaType,
    this.seenIds,
  });

  @override
  State<_HeroBannerWrapper> createState() => _HeroBannerWrapperState();
}

class _HeroBannerWrapperState extends State<_HeroBannerWrapper> {
  late Stream<List<dynamic>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = HomeContentBuilder._heroItemsStream(
      widget.mode,
      widget.cinemaType,
      widget.seenIds,
    );
  }

  @override
  void didUpdateWidget(covariant _HeroBannerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.cinemaType != widget.cinemaType) {
      _stream = HomeContentBuilder._heroItemsStream(
        widget.mode,
        widget.cinemaType,
        widget.seenIds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = sl<LanguageService>().currentLanguage;

    return StreamBuilder<List<dynamic>>(
      key: ValueKey('hero_${widget.mode.index}_${widget.cinemaType.index}_$languageCode'),
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 350,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white24,
              ),
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
                builder:
                    (_) =>
                        item is Book
                            ? BookDetailPage(book: item)
                            : MovieDetailPage(media: item),
              ),
            );
          },
        );
      },
    );
  }


}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}
