import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/repositories/tv_progress_repository.dart';
import '../domain/entities/tv_series_progress.dart';

class SupabaseTvProgressRepositoryImpl implements TvProgressRepository {
  final SupabaseClient _supabase;
  static const String _tableName = 'user_tv_progress';

  final Map<String, TvSeriesProgress> _progressCache = {};
  final Map<String, StreamController<TvSeriesProgress?>> _progressControllers =
      {};
  final Map<String, StreamController<List<TvSeriesProgress>>>
      _allProgressControllers = {};

  SupabaseTvProgressRepositoryImpl({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<TvSeriesProgress?> getProgress(String userId, int seriesId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('series_id', seriesId)
          .maybeSingle();

      if (response == null) return null;

      final progress = TvSeriesProgress.fromMap(response);
      _cacheProgress(progress);
      return progress;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveProgress(TvSeriesProgress progress) async {
    await _supabase
        .from(_tableName)
        .upsert(progress.toMap(), onConflict: 'user_id, series_id');
    _emitProgress(progress);
  }

  @override
  Stream<TvSeriesProgress?> watchProgress(String userId, int seriesId) {
    late StreamController<TvSeriesProgress?> controller;
    StreamSubscription<TvSeriesProgress?>? localSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? realtimeSubscription;

    controller = StreamController<TvSeriesProgress?>(
      onListen: () {
        final key = _progressKey(userId, seriesId);
        if (_progressCache.containsKey(key)) {
          controller.add(_progressCache[key]);
        }

        localSubscription = _progressController(key).stream.listen((progress) {
          if (!controller.isClosed) controller.add(progress);
        });

        () async {
          final initialProgress = await getProgress(userId, seriesId);
          if (!controller.isClosed) controller.add(initialProgress);

          realtimeSubscription = _supabase
              .from(_tableName)
              .stream(primaryKey: ['id'])
              .eq('user_id', userId)
              .listen(
                (events) {
                  final filteredEvents = events
                      .where((row) => row['series_id'] == seriesId)
                      .toList();

                  if (filteredEvents.isEmpty) {
                    _emitProgressRemoval(userId, seriesId);
                    return;
                  }

                  _emitProgress(
                    TvSeriesProgress.fromMap(filteredEvents.first),
                  );
                },
                onError: (_) {},
              );
        }();
      },
      onCancel: () async {
        await localSubscription?.cancel();
        await realtimeSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<TvSeriesProgress>> watchAllUserProgress(String userId) {
    late StreamController<List<TvSeriesProgress>> controller;
    StreamSubscription<List<TvSeriesProgress>>? localSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? realtimeSubscription;

    controller = StreamController<List<TvSeriesProgress>>(
      onListen: () {
        final cachedProgress = _cachedUserProgress(userId);
        if (cachedProgress.isNotEmpty) {
          controller.add(cachedProgress);
        }

        localSubscription = _allProgressController(userId).stream.listen(
          (progressList) {
            if (!controller.isClosed) controller.add(progressList);
          },
        );

        () async {
          final initialProgress = await _fetchAllUserProgress(userId);
          _replaceUserProgressCache(userId, initialProgress);
          if (!controller.isClosed) controller.add(initialProgress);

          realtimeSubscription = _supabase
              .from(_tableName)
              .stream(primaryKey: ['id'])
              .eq('user_id', userId)
              .listen(
                (events) {
                  final uniqueMap = <int, TvSeriesProgress>{};

                  for (var event in events) {
                    final progress = TvSeriesProgress.fromMap(event);
                    uniqueMap[progress.seriesId] = progress;
                  }

                  final progressList = _sortProgress(uniqueMap.values);
                  _replaceUserProgressCache(userId, progressList);
                  _emitAllUserProgress(userId);
                },
                onError: (_) {},
              );
        }();
      },
      onCancel: () async {
        await localSubscription?.cancel();
        await realtimeSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> deleteProgress(String userId, int seriesId) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('user_id', userId)
        .eq('series_id', seriesId);
    _emitProgressRemoval(userId, seriesId);
  }

  Future<List<TvSeriesProgress>> _fetchAllUserProgress(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId);

      final uniqueMap = <int, TvSeriesProgress>{};
      for (final row in response) {
        final progress = TvSeriesProgress.fromMap(row);
        uniqueMap[progress.seriesId] = progress;
      }

      return _sortProgress(uniqueMap.values);
    } catch (_) {
      return _cachedUserProgress(userId);
    }
  }

  StreamController<TvSeriesProgress?> _progressController(String key) {
    return _progressControllers.putIfAbsent(
      key,
      () => StreamController<TvSeriesProgress?>.broadcast(sync: true),
    );
  }

  StreamController<List<TvSeriesProgress>> _allProgressController(
    String userId,
  ) {
    return _allProgressControllers.putIfAbsent(
      userId,
      () => StreamController<List<TvSeriesProgress>>.broadcast(sync: true),
    );
  }

  void _emitProgress(TvSeriesProgress progress) {
    _cacheProgress(progress);
    _progressController(
      _progressKey(progress.userId, progress.seriesId),
    ).add(progress);
    _emitAllUserProgress(progress.userId);
  }

  void _emitProgressRemoval(String userId, int seriesId) {
    final key = _progressKey(userId, seriesId);
    _progressCache.remove(key);
    _progressController(key).add(null);
    _emitAllUserProgress(userId);
  }

  void _cacheProgress(TvSeriesProgress progress) {
    _progressCache[_progressKey(progress.userId, progress.seriesId)] =
        progress;
  }

  void _replaceUserProgressCache(
    String userId,
    Iterable<TvSeriesProgress> progressList,
  ) {
    _progressCache.removeWhere((key, _) => key.startsWith('$userId::'));
    for (final progress in progressList) {
      _cacheProgress(progress);
    }
  }

  void _emitAllUserProgress(String userId) {
    _allProgressController(userId).add(_cachedUserProgress(userId));
  }

  List<TvSeriesProgress> _cachedUserProgress(String userId) {
    return _sortProgress(
      _progressCache.entries
          .where((entry) => entry.key.startsWith('$userId::'))
          .map((entry) => entry.value),
    );
  }

  List<TvSeriesProgress> _sortProgress(
    Iterable<TvSeriesProgress> progressList,
  ) {
    final sortedProgress = progressList.toList();
    sortedProgress.sort((a, b) {
      final bDate = b.lastWatchedDate;
      final aDate = a.lastWatchedDate;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return sortedProgress;
  }

  String _progressKey(String userId, int seriesId) => '$userId::$seriesId';
}
