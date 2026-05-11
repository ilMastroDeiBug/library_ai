class TvSeriesProgress {
  static const Object _unset = Object();

  final String userId;
  final int seriesId;
  final List<String> watchedEpisodes;
  final int streakCount;
  final DateTime? lastWatchedDate;

  TvSeriesProgress({
    required this.userId,
    required this.seriesId,
    this.watchedEpisodes = const [],
    this.streakCount = 0,
    this.lastWatchedDate,
  });

  // Calcolo dei giorni trascorsi dalla mezzanotte
  int get deltaDays {
    if (lastWatchedDate == null) return -1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(
      lastWatchedDate!.year,
      lastWatchedDate!.month,
      lastWatchedDate!.day,
    );

    return today.difference(last).inDays;
  }

  bool get isSafe => deltaDays == 0;
  bool get isLost => deltaDays > 1 || deltaDays == -1;
  int get currentStreak => isLost ? 0 : streakCount;
  bool get isActive => currentStreak >= 3;

  TvSeriesProgress copyWith({
    List<String>? watchedEpisodes,
    int? streakCount,
    Object? lastWatchedDate = _unset,
  }) {
    return TvSeriesProgress(
      userId: userId,
      seriesId: seriesId,
      watchedEpisodes: watchedEpisodes ?? this.watchedEpisodes,
      streakCount: streakCount ?? this.streakCount,
      lastWatchedDate: identical(lastWatchedDate, _unset)
          ? this.lastWatchedDate
          : lastWatchedDate as DateTime?,
    );
  }

  factory TvSeriesProgress.fromMap(Map<String, dynamic> map) {
    return TvSeriesProgress(
      userId: map['user_id'] ?? '',
      seriesId: map['series_id'] ?? 0,
      watchedEpisodes: List<String>.from(map['watched_episodes'] ?? []),
      streakCount: map['streak_count'] ?? 0,
      lastWatchedDate: map['last_watched_date'] != null
          ? DateTime.parse(map['last_watched_date']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'series_id': seriesId,
      'watched_episodes': watchedEpisodes,
      'streak_count': streakCount,
      'last_watched_date': lastWatchedDate?.toUtc().toIso8601String(),
    };
  }
}
