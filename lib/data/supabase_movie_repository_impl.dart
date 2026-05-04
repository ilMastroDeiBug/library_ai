import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/models/movie_widget/watch_provider_model.dart';
import 'package:library_ai/services/utility_services/network_status_service.dart';
import 'package:library_ai/injection_container.dart';

class SupabaseMovieRepositoryImpl implements MovieRepository {
  final SupabaseClient _supabase;
  final TmdbService _tmdbService;

  static const String _tableName = 'user_watchlist';

  SupabaseMovieRepositoryImpl({
    SupabaseClient? supabaseClient,
    TmdbService? tmdbService,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _tmdbService = tmdbService ?? TmdbService();

  @override
  Stream<List<dynamic>> getWatchlistStream(
    String userId,
    String status,
  ) async* {
    final cacheKey = 'watchlist_${userId}_$status';
    final cacheBox = Hive.box('cinelib_cache');

    // 1. CARICA LA CACHE
    final cachedRows = _readCachedRows(cacheBox, cacheKey);
    if (cachedRows != null) {
      yield _mapWatchlistRowsToEntities(cachedRows, status);
    }

    // 2. BLOCCO OFFLINE
    if (!sl<NetworkStatusService>().isOnline) return;

    // 3. STREAM SUPABASE PULITO
    try {
      final supabaseStream = _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      await for (final snapshot in supabaseStream) {
        final rows = snapshot
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        final filteredRows = rows
            .where((row) => row['status'] == status)
            .toList();

        await cacheBox.put(cacheKey, filteredRows);
        for (final row in filteredRows) {
          final mediaId = row['media_id'];
          if (mediaId != null) {
            await cacheBox.put('media_${userId}_$mediaId', row);
          }
        }

        yield _mapWatchlistRowsToEntities(filteredRows, status);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>>? _readCachedRows(Box cacheBox, String cacheKey) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! List) return null;
    return cached
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  List<dynamic> _mapWatchlistRowsToEntities(
    List<Map<String, dynamic>> rows,
    String status,
  ) {
    return rows.where((row) => row['status'] == status).map((row) {
      final type = row['type'] as String? ?? 'movie';
      final mediaId = int.tryParse(row['media_id'].toString()) ?? 0;
      final rawData = Map<String, dynamic>.from(row['raw_data'] as Map? ?? {});
      rawData['status'] = row['status'];
      rawData['aiAnalysis'] = row['ai_analysis'];
      rawData['type'] = type;

      return (type == 'tv')
          ? TvSeries.fromFirestore(rawData, mediaId)
          : Movie.fromFirestore(rawData, mediaId);
    }).toList();
  }

  @override
  Stream<dynamic> getSingleMediaStream(String userId, int id) async* {
    final cacheKey = 'media_${userId}_$id';
    final cacheBox = Hive.box('cinelib_cache');

    final cachedRow = _readCachedRow(cacheBox, cacheKey);
    if (cachedRow != null) {
      yield _mapWatchlistRowToEntity(cachedRow);
    }

    if (!sl<NetworkStatusService>().isOnline) return;

    try {
      final supabaseStream = _supabase
          .from(_tableName)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId);

      await for (final snapshot in supabaseStream) {
        final filteredSnapshot = snapshot.where((row) {
          final rowMediaId = int.tryParse(row['media_id'].toString()) ?? 0;
          return rowMediaId == id;
        }).toList();

        if (filteredSnapshot.isEmpty) {
          yield null;
          continue;
        }

        final row = Map<String, dynamic>.from(filteredSnapshot.first);
        await cacheBox.put(cacheKey, row);

        yield _mapWatchlistRowToEntity(row);
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _readCachedRow(Box cacheBox, String cacheKey) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! Map) return null;
    return Map<String, dynamic>.from(cached);
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

    await _supabase
        .from(_tableName)
        .upsert(payload, onConflict: 'user_id, media_id, type');

    // Aggiornamento cache istantaneo
    final cacheBox = Hive.box('cinelib_cache');
    await cacheBox.put('media_${userId}_${movie.id}', payload);
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

    await _supabase
        .from(_tableName)
        .upsert(payload, onConflict: 'user_id, media_id, type');

    // Aggiornamento cache istantaneo
    final cacheBox = Hive.box('cinelib_cache');
    await cacheBox.put('media_${userId}_${series.id}', payload);
  }

  @override
  Future<void> updateStatus(String userId, int id, String newStatus) async {
    final timestamp = DateTime.now().toIso8601String();

    await _supabase
        .from(_tableName)
        .update({'status': newStatus, 'timestamp': timestamp})
        .eq('user_id', userId)
        .eq('media_id', id);

    // FIX CHIAVE: Allineiamo la cache locale per la Detail Page
    final cacheBox = Hive.box('cinelib_cache');
    final cacheKey = 'media_${userId}_$id';
    final cachedRow = cacheBox.get(cacheKey);
    if (cachedRow is Map) {
      final updatedRow = Map<String, dynamic>.from(cachedRow);
      updatedRow['status'] = newStatus;
      updatedRow['timestamp'] = timestamp;
      await cacheBox.put(cacheKey, updatedRow);
    }
  }

  @override
  Future<void> deleteItem(String userId, int id) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('user_id', userId)
        .eq('media_id', id);

    // Pialliamo anche la cache
    final cacheBox = Hive.box('cinelib_cache');
    await cacheBox.delete('media_${userId}_$id');
  }

  @override
  Future<void> saveAnalysis(String userId, int id, String analysis) async {
    await _supabase
        .from(_tableName)
        .update({
          'ai_analysis': analysis,
          'timestamp': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('media_id', id);
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
  Future<List<Review>> getReviews(int id, {bool isTv = false}) async =>
      _tmdbService.fetchReviews(id, isTv: isTv);

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
