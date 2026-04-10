import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/models/movie_widget/watch_provider_model.dart';

class SupabaseMovieRepositoryImpl implements MovieRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TmdbService _tmdbService = TmdbService();

  static const String _tableName = 'user_watchlist';

  @override
  Stream<List<dynamic>> getWatchlistStream(String userId, String status) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .map((snapshot) {
          // 1. Filtriamo per status
          final filteredRows = snapshot
              .where((row) => row['status'] == status)
              .toList();

          // 2. Mappiamo i dati SQL nelle tue Entities
          return filteredRows.map((row) {
            final type = row['type'] as String;
            final int mediaId = row['media_id'] as int;

            // Estraiamo il JSON originale salvato
            final Map<String, dynamic> rawData = row['raw_data'] ?? {};

            // Reiniettiamo i valori controllati dal Database dentro la mappa
            rawData['status'] = row['status'];
            rawData['aiAnalysis'] = row['ai_analysis'];
            rawData['type'] = type;

            return (type == 'tv')
                ? TvSeries.fromFirestore(rawData, mediaId)
                : Movie.fromFirestore(rawData, mediaId);
          }).toList();
        });
  }

  // <-- NUOVO: Implementazione dello stream per la pagina di dettaglio
  @override
  Stream<dynamic> getSingleMediaStream(String userId, int id) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId) // <-- Usiamo l'unico .eq() permesso dallo stream
        .map((snapshot) {
          // <-- FIX: Filtriamo il media_id localmente in Dart!
          final filteredSnapshot = snapshot.where((row) {
            final rowMediaId = int.tryParse(row['media_id'].toString()) ?? 0;
            return rowMediaId == id;
          }).toList();

          if (filteredSnapshot.isEmpty) return null;

          final row = filteredSnapshot.first;
          final type = row['type'] as String;

          // Copia sicura e tipizzata
          final Map<String, dynamic> rawData = Map<String, dynamic>.from(
            row['raw_data'] as Map? ?? {},
          );

          rawData['status'] = row['status'];
          rawData['aiAnalysis'] = row['ai_analysis'];
          rawData['type'] = type;

          return (type == 'tv')
              ? TvSeries.fromFirestore(rawData, id)
              : Movie.fromFirestore(rawData, id);
        });
  }

  @override
  Future<void> saveMovie(Movie movie, String userId) async {
    await _supabase.from(_tableName).upsert({
      'user_id': userId,
      'media_id': movie.id,
      'type': 'movie',
      'status': movie.status,
      'ai_analysis': movie.aiAnalysis,
      'raw_data': movie.toMap(), // Salviamo l'intero film in formato JSON
      'timestamp': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, media_id, type');
  }

  @override
  Future<void> saveTvSeries(TvSeries series, String userId) async {
    await _supabase.from(_tableName).upsert({
      'user_id': userId,
      'media_id': series.id,
      'type': 'tv',
      'status': series.status,
      'ai_analysis': series.aiAnalysis,
      'raw_data': series.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, media_id, type');
  }

  @override
  Future<void> updateStatus(String userId, int id, String newStatus) async {
    await _supabase
        .from(_tableName)
        .update({'status': newStatus})
        .eq('user_id', userId)
        .eq('media_id', id);
  }

  @override
  Future<void> deleteItem(String userId, int id) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('user_id', userId)
        .eq('media_id', id);
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

  // =========================================================
  // --- METODI API TMDB (Identici a prima, non toccano DB) --
  // =========================================================

  @override
  Future<List<Movie>> getMoviesByCategory(
    String categoryPath, {
    int page = 1,
  }) async {
    List<Movie> rawList;
    if (categoryPath == 'trending') {
      rawList = await _tmdbService.fetchTrendingMovies(page: page);
    } else if (categoryPath.contains('with_genres=')) {
      final genreId = categoryPath.split('=').last;
      rawList = await _tmdbService.fetchMoviesByGenre(genreId, page: page);
    } else {
      rawList = await _tmdbService.fetchMoviesByCategory(
        categoryPath,
        page: page,
      );
    }
    return rawList
        .where((movie) => movie.posterPath.isNotEmpty && movie.voteCount > 0)
        .toList();
  }

  @override
  Future<List<TvSeries>> getTvSeriesByCategory(
    String categoryPath, {
    int page = 1,
  }) async {
    List<TvSeries> rawList;
    if (categoryPath == 'trending') {
      rawList = await _tmdbService.fetchTvTrending(page: page);
    } else if (categoryPath.contains('with_genres=')) {
      final genreId = categoryPath.split('=').last;
      rawList = await _tmdbService.fetchTvByGenre(genreId, page: page);
    } else {
      rawList = await _tmdbService.fetchTvSeriesByCategory(
        categoryPath,
        page: page,
      );
    }
    return rawList
        .where((tv) => tv.posterPath.isNotEmpty && tv.voteCount > 0)
        .toList();
  }

  @override
  Future<List<Review>> getReviews(int id, {bool isTv = false}) async =>
      _tmdbService.fetchReviews(id, isTv: isTv);

  @override
  Future<List<CastMember>> getCast(int id, {bool isTv = false}) async =>
      _tmdbService.fetchCast(id, isTv: isTv);

  @override
  Future<List<Movie>> searchMovies(String query) async =>
      _tmdbService.searchMovies(query);

  @override
  Future<List<TvSeries>> searchTvSeries(String query) async =>
      _tmdbService.searchTvSeries(query);

  @override
  Future<String?> getTrailerKey(int id, {bool isTv = false}) async =>
      await _tmdbService.fetchTrailerKey(id, isTv: isTv);

  @override
  Future<WatchProvidersResult?> getWatchProviders(
    int id, {
    bool isTv = false,
  }) async => await _tmdbService.fetchWatchProviders(id, isTv: isTv);
}
