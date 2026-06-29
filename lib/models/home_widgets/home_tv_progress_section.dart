import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../injection_container.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/tv_series_progress_use_cases.dart';
import '../../domain/use_cases/tv_series_use_cases.dart';
import '../../domain/entities/tv_series_progress.dart';
import '../../domain/entities/tv_series.dart';
import '../../Pages/movie_detail_page.dart';
import '../movie_widget/streak_widget.dart';
import '../../services/utility_services/watchlist_realtime_notifier.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class HomeTvProgressSection extends StatefulWidget {
  const HomeTvProgressSection({super.key});

  @override
  State<HomeTvProgressSection> createState() => _HomeTvProgressSectionState();
}

class _HomeTvProgressSectionState extends State<HomeTvProgressSection> {
  late Stream<List<TvSeriesProgress>> _progressStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final user = sl<AuthRepository>().currentUser;
    _currentUserId = user?.id;
    if (_currentUserId != null) {
      _progressStream = sl<GetAllUserProgressUseCase>().call(_currentUserId!);
    } else {
      _progressStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return const SizedBox.shrink();

    if (user.id != _currentUserId) {
      _currentUserId = user.id;
      _progressStream = sl<GetAllUserProgressUseCase>().call(_currentUserId!);
    }

    return ValueListenableBuilder<Map<int, String>>(
      valueListenable: globalOptimisticStatus,
      builder: (context, optimisticStatuses, child) {
        return StreamBuilder<List<TvSeriesProgress>>(
          stream: _progressStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            // Filtriamo le serie con episodi visti e rispettiamo i cambi stato
            // ottimistici della watchlist.
            final progressList = snapshot.data!
                .where((p) {
                  final optimisticStatus = optimisticStatuses[p.seriesId];
                  if (optimisticStatus != null &&
                      optimisticStatus != 'watching') {
                    return false;
                  }

                  return p.watchedEpisodes.isNotEmpty;
                })
                .toList();

            if (progressList.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.homeWatching,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.play_circle_fill_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: progressList.length,
                    itemBuilder: (context, index) {
                      final progress = progressList[index];

                      return _ActiveSeriesCard(
                        progress: progress,
                        userId: user.id,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActiveSeriesCard extends StatefulWidget {
  final TvSeriesProgress progress;
  final String userId;

  const _ActiveSeriesCard({required this.progress, required this.userId});

  @override
  State<_ActiveSeriesCard> createState() => _ActiveSeriesCardState();
}

class _ActiveSeriesCardState extends State<_ActiveSeriesCard> {
  late Stream<dynamic> _tvSeriesStream;

  @override
  void initState() {
    super.initState();
    _tvSeriesStream = sl<GetSingleTvSeriesUseCase>().call(
      widget.userId,
      widget.progress.seriesId.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _ActiveSeriesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.progress.seriesId != widget.progress.seriesId) {
      _tvSeriesStream = sl<GetSingleTvSeriesUseCase>().call(
        widget.userId,
        widget.progress.seriesId.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recuperiamo i dati della serie TV dal DB tramite ID per avere la locandina
    return StreamBuilder<dynamic>(
      stream: _tvSeriesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        final TvSeries series = snapshot.data as TvSeries;
        if (series.status != 'watching') return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(right: 15),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailPage(media: series),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(series.fullPosterUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: StreakWidget(progress: widget.progress),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
