import 'dart:async';
import 'package:flutter/material.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/movie_use_cases.dart';
import '../../domain/use_cases/tv_series_use_cases.dart';
import '../../domain/use_cases/tv_series_progress_use_cases.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';
import '../../domain/entities/tv_series_progress.dart';
import '../../Pages/movie_detail_page.dart';
import '../../models/movie_widget/streak_widget.dart';
import '../movie_widget/movie_card.dart';
import '../../services/utility_services/language_service.dart';

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
  late Stream<List<dynamic>> _stream;
  final LanguageService _languageService = sl<LanguageService>();

  @override
  void initState() {
    super.initState();
    _stream = _fetchAndFilter();
    _languageService.addListener(_handleLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _stream = _fetchAndFilter();
    });
  }

  Stream<List<dynamic>> _fetchAndFilter() async* {
    int pageToFetch = 1;

    final Stream<List<dynamic>> stream = widget.isTv
        ? sl<GetTvSeriesByCategoryUseCase>()
              .call(widget.path, page: pageToFetch)
              .map((items) => List<dynamic>.from(items))
        : sl<GetMoviesByCategoryUseCase>()
              .call(widget.path, page: pageToFetch)
              .map((items) => List<dynamic>.from(items));

    final Set<int> localAddedIds = {};

    await for (final rawItems in stream) {
      widget.seenIds.removeAll(localAddedIds);
      localAddedIds.clear();

      List<dynamic> uniqueItems = [];
      for (var item in rawItems) {
        int currentId = 0;
        if (item is Movie) {
          currentId = item.id;
        } else if (item is TvSeries) {
          currentId = item.id;
        } else {
          continue;
        }

        if (!widget.seenIds.contains(currentId)) {
          uniqueItems.add(item);
          widget.seenIds.add(currentId);
          localAddedIds.add(currentId);
        }
      }

      if (widget.path.contains('with_genres=')) {
        uniqueItems.shuffle();
      }

      // FIX FONDAMENTALE: Yield incondizionato.
      // Se la lista è vuota (es. hai rimosso l'ultimo film in corso), invia [] alla UI per pulirla!
      yield uniqueItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRepository>().currentUser;

    return StreamBuilder<List<dynamic>>(
      key: ValueKey('list_${widget.title}_${widget.isTv}'),
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orangeAccent,
            ),
          );
        }

        final items = snapshot.data ?? [];

        // Se è vuota, scompare tutto il blocco orizzontale in modo pulito
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white54,
                    size: 16,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final mediaItem = items[index];

                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Stack(
                      children: [
                        MovieCard(
                          media: mediaItem,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailPage(media: mediaItem),
                            ),
                          ),
                        ),

                        if (widget.isTv &&
                            mediaItem is TvSeries &&
                            user != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: StreamBuilder<TvSeriesProgress?>(
                              stream: sl<GetSeriesProgressUseCase>().call(
                                user.id,
                                mediaItem.id,
                              ),
                              builder: (context, streakSnapshot) {
                                if (!streakSnapshot.hasData ||
                                    streakSnapshot.data == null) {
                                  return const SizedBox.shrink();
                                }
                                return StreakWidget(
                                  progress: streakSnapshot.data!,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
