import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/models/movie_widget/watch_provider_model.dart';
import 'package:library_ai/services/utility_services/network_status_service.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/services/utility_services/cinelib_cache_service.dart';

class SupabaseMovieRepositoryImpl implements MovieRepository {
  final SupabaseClient _supabase;
  final TmdbService _tmdbService;
  final CinelibCacheService _cacheService;

  static const String _tableName = 'user_watchlist';
  static const List<String> _watchlistStatuses = [
    'towatch',
    'watching',
    'watched',
  ];

  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _watchlistControllers = {};
  final Map<String, StreamController<Map<String, dynamic>?>>
      _mediaControllers = {};

  SupabaseMovieRepositoryImpl({
    SupabaseClient? supabaseClient,
    TmdbService? tmdbService,
    CinelibCacheService? cacheService,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _tmdbService = tmdbService ?? TmdbService(),
       _cacheService = cacheService ?? CinelibCacheService();

  @override
  Stream<List<dynamic>> getWatchlistStream(String userId, String status) {
    late StreamController<List<dynamic>> controller;
    StreamSubscription<List<Map<String, dynamic>>>? localSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? realtimeSubscription;

    controller = StreamController<List<dynamic>>(
      onListen: () {
        () async {
          final cacheKey = 'watchlist_${userId}_$status';
          final cacheBox = Hive.box('cinelib_cache');

          final cachedRows = _readCachedRows(cacheBox, cacheKey);
          if (cachedRows != null) {
            controller.add(_mapWatchlistRowsToEntities(cachedRows, status));
          } else {
            await cacheBox.put(cacheKey, <Map<String, dynamic>>[]);
            controller.add(const []);
          }

          localSubscription = _watchlistController(
            userId,
            status,
          ).stream.listen((rows) {
            if (!controller.isClosed) {
              controller.add(_mapWatchlistRowsToEntities(rows, status));
            }
          });

          if (!sl<NetworkStatusService>().isOnline) return;

          realtimeSubscription = _supabase
              .from(_tableName)
              .stream(primaryKey: ['id'])
              .eq('user_id', userId)
              .order('timestamp', ascending: false)
              .listen(
                (snapshot) async {
                  final rows = snapshot
                      .map((row) => Map<String, dynamic>.from(row))
                      .toList();
                  final filteredRows = rows
                      .where((row) => row['status'] == status)
                      .toList();
                  final finalRows = _deduplicateRowsByMediaId(filteredRows);

                  await cacheBox.put(cacheKey, finalRows);
                  for (final row in finalRows) {
                    final mediaId = row['media_id'];
                    if (mediaId != null) {
                      await cacheBox.put('media_${userId}_$mediaId', row);
                    }
                  }

                  _emitWatchlistRows(userId, status, finalRows);
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
  Stream<dynamic> getSingleMediaStream(String userId, int id) {
    late StreamController<dynamic> controller;
    StreamSubscription<Map<String, dynamic>?>? localSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? realtimeSubscription;

    controller = StreamController<dynamic>(
      onListen: () {
        final cacheKey = 'media_${userId}_$id';
        final cacheBox = Hive.box('cinelib_cache');

        final cachedRow = _readCachedRow(cacheBox, cacheKey);
        if (cachedRow != null) {
          controller.add(_mapWatchlistRowToEntity(cachedRow));
        }

        localSubscription = _mediaController(userId, id).stream.listen((row) {
          if (controller.isClosed) return;
          controller.add(row == null ? null : _mapWatchlistRowToEntity(row));
        });

        if (!sl<NetworkStatusService>().isOnline) return;

        realtimeSubscription = _supabase
            .from(_tableName)
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .listen(
              (snapshot) async {
                final filteredSnapshot = snapshot
                    .where((row) => row['media_id'] == id)
                    .toList();

                if (filteredSnapshot.isEmpty) {
                  final fallbackRow = _readCachedRow(cacheBox, cacheKey);
                  await _cacheService.deleteMediaItem(
                    userId: userId,
                    mediaId: id,
                  );

                  if (fallbackRow != null) {
                    final removedRow = Map<String, dynamic>.from(fallbackRow);
                    removedRow['status'] = 'none';
                    _emitMediaRow(userId, id, removedRow);
                  } else {
                    _emitMediaRow(userId, id, null);
                  }
                  await _emitWatchlistCache(userId);
                  return;
                }

                final row = Map<String, dynamic>.from(filteredSnapshot.first);
                await _cacheService.upsertMediaItem(
                  userId: userId,
                  mediaId: id,
                  row: row,
                );

                _emitMediaRow(userId, id, row);
                await _emitWatchlistCache(userId);
              },
              onError: (_) {},
            );
      },
      onCancel: () async {
        await localSubscription?.cancel();
        await realtimeSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<Map<String, dynamic>>? _readCachedRows(Box cacheBox, String cacheKey) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! List) return null;
    return cached
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Map<String, dynamic>? _readCachedRow(Box cacheBox, String cacheKey) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! Map) return null;
    return Map<String, dynamic>.from(cached);
  }

  List<dynamic> _mapWatchlistRowsToEntities(
    List<Map<String, dynamic>> rows,
    String status,
  ) {
    return rows.where((row) => row['status'] == status).map((row) {
      return _mapWatchlistRowToEntity(row);
    }).toList();
  }

  dynamic _mapWatchlistRowToEntity(Map<String, dynamic> row) {
    final type = row['type'] as String? ?? 'movie';
    final mediaId = int.tryParse(row['media_id'].toString()) ?? 0;
    final rawData = Map<String, dynamic>.from(row['raw_data'] as Map? ?? {});
    rawData['status'] = row['status'];
    rawData['aiAnalysis'] = row['ai_analysis'];
    rawData['type'] = type;

    return (type == 'tv')
        ? TvSeries.fromFirestore(rawData, mediaId)
        : Movie.fromFirestore(rawData, mediaId);
  }

  List<Map<String, dynamic>> _deduplicateRowsByMediaId(
    List<Map<String, dynamic>> rows,
  ) {
    final uniqueMap = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final type = row['type'] as String? ?? 'movie';
      final mediaId = int.tryParse(row['media_id'].toString()) ?? 0;
      uniqueMap['$type:$mediaId'] = row;
    }
    return uniqueMap.values.toList();
  }

  StreamController<List<Map<String, dynamic>>> _watchlistController(
    String userId,
    String status,
  ) {
    return _watchlistControllers.putIfAbsent(
      _watchlistKey(userId, status),
      () => StreamController<List<Map<String, dynamic>>>.broadcast(sync: true),
    );
  }

  StreamController<Map<String, dynamic>?> _mediaController(
    String userId,
    int mediaId,
  ) {
    return _mediaControllers.putIfAbsent(
      _mediaKey(userId, mediaId),
      () => StreamController<Map<String, dynamic>?>.broadcast(sync: true),
    );
  }

  void _emitWatchlistRows(
    String userId,
    String status,
    List<Map<String, dynamic>> rows,
  ) {
    _watchlistController(userId, status).add(_deduplicateRowsByMediaId(rows));
  }

  Future<void> _emitWatchlistCache(
    String userId, {
    Iterable<String>? statuses,
  }) async {
    final cacheBox = Hive.box('cinelib_cache');
    for (final status in statuses ?? _watchlistStatuses) {
      final cacheKey = 'watchlist_${userId}_$status';
      final cachedRows = _readCachedRows(cacheBox, cacheKey) ?? [];
      _emitWatchlistRows(userId, status, cachedRows);
    }
  }

  void _emitMediaRow(
    String userId,
    int mediaId,
    Map<String, dynamic>? row,
  ) {
    _mediaController(userId, mediaId).add(row);
  }

  String _watchlistKey(String userId, String status) => '$userId::$status';

  String _mediaKey(String userId, int mediaId) => '$userId::$mediaId';

  @override
  Future<void> saveMovie(Movie movie, String userId) async {
    final payload = {
      'user_id': userId,
      'media_id': movie.id,
      'type': 'movie',
      'status': movie.status,
      'ai_analysis': movie.aiAnalysis,
      'raw_data': movie.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Optimistic Update
    await _cacheService.upsertMediaItem(
      userId: userId,
      mediaId: movie.id,
      row: payload,
    );
    _emitMediaRow(userId, movie.id, payload);
    await _emitWatchlistCache(userId);

    try {
      final existing = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('media_id', movie.id)
          .eq('type', 'movie')
          .maybeSingle();

      if (existing != null) {
        await _supabase.from(_tableName).update(payload).eq('id', existing['id']);
      } else {
        await _supabase.from(_tableName).insert(payload);
      }
    } catch (_) {
      // Ignora errore: cache locale aggiornata per offline
    }
  }

  @override
  Future<void> saveTvSeries(TvSeries series, String userId) async {
    final payload = {
      'user_id': userId,
      'media_id': series.id,
      'type': 'tv',
      'status': series.status,
      'ai_analysis': series.aiAnalysis,
      'raw_data': series.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Optimistic Update
    await _cacheService.upsertMediaItem(
      userId: userId,
      mediaId: series.id,
      row: payload,
    );
    _emitMediaRow(userId, series.id, payload);
    await _emitWatchlistCache(userId);

    try {
      final existing = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .eq('media_id', series.id)
          .eq('type', 'tv')
          .maybeSingle();

      if (existing != null) {
        await _supabase.from(_tableName).update(payload).eq('id', existing['id']);
      } else {
        await _supabase.from(_tableName).insert(payload);
      }
    } catch (_) {
      // Ignora errore per offline
    }
  }

  @override
  Future<void> updateStatus(String userId, int id, String newStatus) async {
    final timestamp = DateTime.now().toIso8601String();

    // Optimistic Update
    await _cacheService.updateMediaStatus(
      userId: userId,
      mediaId: id,
      newStatus: newStatus,
      timestamp: timestamp,
    );

    final cacheBox = Hive.box('cinelib_cache');
    final updatedRow = _readCachedRow(cacheBox, 'media_${userId}_$id');
    if (updatedRow != null) {
      _emitMediaRow(userId, id, updatedRow);
    }
    await _emitWatchlistCache(userId);

    try {
      await _supabase
          .from(_tableName)
          .update({'status': newStatus, 'timestamp': timestamp})
          .eq('user_id', userId)
          .eq('media_id', id);
    } catch (_) {}
  }

  @override
  Future<void> deleteItem(String userId, int id) async {
    final cacheBox = Hive.box('cinelib_cache');
    final cachedRow = _readCachedRow(cacheBox, 'media_${userId}_$id');

    // Optimistic Update
    await _cacheService.deleteMediaItem(userId: userId, mediaId: id);

    if (cachedRow != null) {
      final removedRow = Map<String, dynamic>.from(cachedRow);
      removedRow['status'] = 'none';
      _emitMediaRow(userId, id, removedRow);
    } else {
      _emitMediaRow(userId, id, null);
    }
    await _emitWatchlistCache(userId);

    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
          .eq('media_id', id);
    } catch (_) {}
  }

  @override
  Future<void> saveAnalysis(String userId, int id, String analysis) async {
    final timestamp = DateTime.now().toIso8601String();
    // Optimistic Update
    final cacheBox = Hive.box('cinelib_cache');
    final cachedRow = _readCachedRow(cacheBox, 'media_${userId}_$id');
    if (cachedRow != null) {
      cachedRow['ai_analysis'] = analysis;
      cachedRow['timestamp'] = timestamp;
      await _cacheService.upsertMediaItem(
        userId: userId,
        mediaId: id,
        row: cachedRow,
      );
      _emitMediaRow(userId, id, cachedRow);
      await _emitWatchlistCache(userId);
    }

    try {
      await _supabase
          .from(_tableName)
          .update({'ai_analysis': analysis, 'timestamp': timestamp})
          .eq('user_id', userId)
          .eq('media_id', id);
    } catch (_) {}
  }

  @override
  Stream<List<Movie>> getMoviesByCategory(
    String categoryPath, {
    int page = 1,
  }) async* {
    Stream<List<Movie>> rawStream;
    if (categoryPath == 'trending') {
      rawStream = _tmdbService.fetchTrendingMovies(page: page);
    } else if (categoryPath.contains('with_genres=')) {
      final genreId = categoryPath.split('=').last;
      rawStream = _tmdbService.fetchMoviesByGenre(genreId, page: page);
    } else {
      rawStream = _tmdbService.fetchMoviesByCategory(categoryPath, page: page);
    }
    yield* rawStream.map(
      (rawList) => rawList
          .where((movie) => movie.posterPath.isNotEmpty && movie.voteCount > 0)
          .toList(),
    );
  }

  @override
  Stream<List<TvSeries>> getTvSeriesByCategory(
    String categoryPath, {
    int page = 1,
  }) async* {
    Stream<List<TvSeries>> rawStream;
    if (categoryPath == 'trending') {
      rawStream = _tmdbService.fetchTvTrending(page: page);
    } else if (categoryPath.contains('with_genres=')) {
      final genreId = categoryPath.split('=').last;
      rawStream = _tmdbService.fetchTvByGenre(genreId, page: page);
    } else {
      rawStream = _tmdbService.fetchTvSeriesByCategory(
        categoryPath,
        page: page,
      );
    }
    yield* rawStream.map(
      (rawList) => rawList
          .where((tv) => tv.posterPath.isNotEmpty && tv.voteCount > 0)
          .toList(),
    );
  }

  @override
  Future<List<CastMember>> getCast(int id, {bool isTv = false}) async =>
      _tmdbService.fetchCast(id, isTv: isTv);

  @override
  Stream<List<Movie>> searchMovies(String query) =>
      _tmdbService.searchMovies(query);

  @override
  Stream<List<TvSeries>> searchTvSeries(String query) =>
      _tmdbService.searchTvSeries(query);

  @override
  Future<String?> getTrailerKey(int id, {bool isTv = false}) async =>
      _tmdbService.fetchTrailerKey(id, isTv: isTv);

  @override
  Future<WatchProvidersResult?> getWatchProviders(
    int id, {
    bool isTv = false,
  }) async => _tmdbService.fetchWatchProviders(id, isTv: isTv);
}
