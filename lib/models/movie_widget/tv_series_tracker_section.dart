import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import '../../domain/use_cases/tv_series_progress_use_cases.dart';
import '../../domain/entities/tv_series_progress.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class TvSeriesTrackerSection extends StatefulWidget {
  final String userId;
  final int seriesId;
  final Map<int, int> episodesPerSeason;

  const TvSeriesTrackerSection({
    super.key,
    required this.userId,
    required this.seriesId,
    required this.episodesPerSeason,
  });

  @override
  State<TvSeriesTrackerSection> createState() => _TvSeriesTrackerSectionState();
}

class _TvSeriesTrackerSectionState extends State<TvSeriesTrackerSection> {
  int _selectedSeason = 1;
  bool _hasAutoSelectedSeason = false;
  late Stream<TvSeriesProgress?> _progressStream;

  @override
  void initState() {
    super.initState();
    if (widget.episodesPerSeason.isNotEmpty) {
      _selectedSeason = widget.episodesPerSeason.keys.first;
    }
    _progressStream = sl<GetSeriesProgressUseCase>().call(
      widget.userId,
      widget.seriesId,
    );
  }

  // Auto-scroll all'ultima stagione guardata alla prima lettura dei dati
  void _checkAndAutoSelectSeason(TvSeriesProgress progress) {
    if (_hasAutoSelectedSeason || progress.watchedEpisodes.isEmpty) return;

    int highestSeason = 1;
    for (String ep in progress.watchedEpisodes) {
      final sStr = ep.split(':')[0].replaceAll('S', '');
      final sNum = int.tryParse(sStr) ?? 1;
      if (sNum > highestSeason) highestSeason = sNum;
    }

    if (widget.episodesPerSeason.containsKey(highestSeason)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedSeason = highestSeason);
      });
    }
    _hasAutoSelectedSeason = true;
  }

  void _showToggleBanner(
    BuildContext context,
    int season,
    int episode,
    bool isCurrentlyWatched,
  ) {
    final titleColor = isCurrentlyWatched
        ? Colors.redAccent
        : Colors.orangeAccent;
    final titleText = isCurrentlyWatched
        ? AppLocalizations.of(context)!.trackerRemoveFromHere
        : AppLocalizations.of(context)!.trackerMarkUpToHere;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.trackerSeasonEpisode(season, episode),
                style: TextStyle(
                  color: titleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      child: Text(
                        AppLocalizations.of(context)!.trackerCancel,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: titleColor,
                        foregroundColor: isCurrentlyWatched
                            ? Colors.white
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        // Chiamata Bulk Magica!
                        sl<ToggleEpisodeWatchedUseCase>().call(
                          widget.userId,
                          widget.seriesId,
                          season,
                          episode,
                          widget.episodesPerSeason,
                          isCurrentlyWatched,
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.trackerConfirm,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.episodesPerSeason.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<TvSeriesProgress?>(
      stream: _progressStream,
      builder: (context, snapshot) {
        final progress =
            snapshot.data ??
            TvSeriesProgress(userId: widget.userId, seriesId: widget.seriesId);
        final watched = progress.watchedEpisodes;

        _checkAndAutoSelectSeason(progress);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.episodesPerSeason.keys.length,
                itemBuilder: (context, index) {
                  final seasonNumber = widget.episodesPerSeason.keys.elementAt(
                    index,
                  );
                  final isSelected = _selectedSeason == seasonNumber;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSeason = seasonNumber),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orangeAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white24,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.trackerSeasonLabel(seasonNumber),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: widget.episodesPerSeason[_selectedSeason] ?? 0,
              itemBuilder: (context, index) {
                final epNum = index + 1;
                final epId = "S$_selectedSeason:E$epNum";
                final isWatched = watched.contains(epId);

                return GestureDetector(
                  onTap: () => _showToggleBanner(
                    context,
                    _selectedSeason,
                    epNum,
                    isWatched,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isWatched
                          ? Colors.orangeAccent.withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isWatched
                            ? Colors.orangeAccent
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isWatched
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.orangeAccent,
                            )
                          : Text(
                              "$epNum",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
