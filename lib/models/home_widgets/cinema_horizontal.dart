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

  static const int _kMinItems = 8;

  Future<List<dynamic>> _fetchPage(int page) async {
    final raw = widget.isTv
        ? await sl<GetTvSeriesByCategoryUseCase>()
              .call(widget.path, page: page)
              .first
        : await sl<GetMoviesByCategoryUseCase>()
              .call(widget.path, page: page)
              .first;
    return List<dynamic>.from(raw);
  }

  List<dynamic> _filterUnique(
    List<dynamic> rawItems,
    Set<int> localAddedIds,
  ) {
    final List<dynamic> unique = [];
    for (final item in rawItems) {
      final int id;
      if (item is Movie) {
        id = item.id;
      } else if (item is TvSeries) {
        id = item.id;
      } else {
        continue;
      }
      if (!widget.seenIds.contains(id)) {
        unique.add(item);
        widget.seenIds.add(id);
        localAddedIds.add(id);
      }
    }
    return unique;
  }

  Stream<List<dynamic>> _fetchAndFilter() async* {
    final List<dynamic> accumulated = [];
    final Set<int> localAddedIds = {};

    // Clear any ids tracked from a previous fetch of this section
    widget.seenIds.removeAll(localAddedIds);
    localAddedIds.clear();

    try {
      // Page 1 — always fetch
      accumulated.addAll(_filterUnique(await _fetchPage(1), localAddedIds));

      // Page 2 — fetch only if still below the minimum
      if (accumulated.length < _kMinItems) {
        accumulated.addAll(_filterUnique(await _fetchPage(2), localAddedIds));
      }

      // Page 3 — fetch only if still below the minimum
      if (accumulated.length < _kMinItems) {
        accumulated.addAll(_filterUnique(await _fetchPage(3), localAddedIds));
      }

      if (widget.path.contains('with_genres=')) {
        accumulated.shuffle();
      }

      yield accumulated;
    } catch (_) {
      if (accumulated.isNotEmpty) {
        yield accumulated;
      } else {
        yield [];
      }
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
          return const SizedBox(
            height: 240,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white24,
              ),
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
