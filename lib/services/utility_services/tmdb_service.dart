// lib/services/utility_services/tmdb_service.dart

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/injection_container.dart';
import '../../models/movie_widget/review_model.dart';
import '../../models/movie_widget/cast_model.dart';
import '../../models/movie_widget/watch_provider_model.dart';
import '../utility_services/language_service.dart';

class TmdbService {
  static const String _accessToken =
      "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0NmU3NmMyMGZiZjE2ZDFjYTMxZGM1NWM0YjQ5MTA4YyIsIm5iZiI6MTc3MDkxNjMzMC42MjEsInN1YiI6IjY5OGUwOWVhN2M5ZjE4Y2M2NGRjZGQ2NSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.LJL0sBW1eiY3GEw81O-RyD2L-DXqbl7sCwVPxEisabE";
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  final http.Client _client;

  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

  String get _language => sl<LanguageService>().currentLanguage;

  // --- FILM (STREAM CACHE-THEN-NETWORK) ---
  Stream<List<Movie>> fetchMoviesByCategory(
    String endpoint, {
    int page = 1,
  }) async* {
    final url = Uri.parse(
      '$_baseUrl/movie/$endpoint?language=$_language&page=$page',
    );
    yield* _streamMovies(url, 'tmdb_movie_${endpoint}_${_language}_page_$page');
  }

  Stream<List<Movie>> fetchMoviesByGenre(
    String genreId, {
    int page = 1,
  }) async* {
    final url = Uri.parse(
      '$_baseUrl/discover/movie?with_genres=$genreId&language=$_language&page=$page',
    );
    yield* _streamMovies(
      url,
      'tmdb_movie_genre_${genreId}_${_language}_page_$page',
    );
  }

  Stream<List<Movie>> fetchTrendingMovies({int page = 1}) async* {
    final url = Uri.parse(
      '$_baseUrl/trending/movie/week?language=$_language&page=$page',
    );
    yield* _streamMovies(url, 'tmdb_trending_movies_${_language}_page_$page');
  }

  Stream<List<Movie>> searchMovies(String query, {int page = 1}) async* {
    if (query.isEmpty) {
      yield [];
      return;
    }
    final url = Uri.parse(
      '$_baseUrl/search/movie?query=${Uri.encodeQueryComponent(query)}&language=$_language&include_adult=false&page=$page',
    );
    yield* _streamMovies(
      url,
      'tmdb_search_movies_${_sanitizeCachePart(query)}_${_language}_page_$page',
    );
  }

  // --- SERIE TV (STREAM CACHE-THEN-NETWORK) ---
  Stream<List<TvSeries>> fetchTvSeriesByCategory(
    String endpoint, {
    int page = 1,
  }) async* {
    final url = Uri.parse(
      '$_baseUrl/tv/$endpoint?language=$_language&page=$page',
    );
    yield* _streamTvSeries(url, 'tmdb_tv_${endpoint}_${_language}_page_$page');
  }

  Stream<List<TvSeries>> fetchTvByGenre(String genreId, {int page = 1}) async* {
    final url = Uri.parse(
      '$_baseUrl/discover/tv?with_genres=$genreId&language=$_language&page=$page',
    );
    yield* _streamTvSeries(
      url,
      'tmdb_tv_genre_${genreId}_${_language}_page_$page',
    );
  }

  Stream<List<TvSeries>> fetchTvTrending({int page = 1}) async* {
    final url = Uri.parse(
      '$_baseUrl/trending/tv/week?language=$_language&page=$page',
    );
    yield* _streamTvSeries(url, 'tmdb_trending_tv_${_language}_page_$page');
  }

  Stream<List<TvSeries>> searchTvSeries(String query, {int page = 1}) async* {
    if (query.isEmpty) {
      yield [];
      return;
    }
    final url = Uri.parse(
      '$_baseUrl/search/tv?query=${Uri.encodeQueryComponent(query)}&language=$_language&include_adult=false&page=$page',
    );
    yield* _streamTvSeries(
      url,
      'tmdb_search_tv_${_sanitizeCachePart(query)}_${_language}_page_$page',
    );
  }

  // --- ATTORI / PERSONE (STREAM CACHE-THEN-NETWORK) ---
  Stream<List<CastMember>> searchActors(String query, {int page = 1}) async* {
    if (query.isEmpty) {
      yield [];
      return;
    }
    final url = Uri.parse(
      '$_baseUrl/search/person?query=${Uri.encodeQueryComponent(query)}&language=$_language&page=$page',
    );
    final cacheKey =
        'tmdb_search_people_${_sanitizeCachePart(query)}_${_language}_page_$page';
    final cacheBox = Hive.box('tmdb_cache');

    final cachedResults = _readCachedResults(cacheBox, cacheKey);
    if (cachedResults != null) {
      yield cachedResults.map(_mapPersonSearchResult).toList();
    }

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await cacheBox.put(cacheKey, results);
        yield results.map(_mapPersonSearchResult).toList();
      }
    } catch (_) {
      // Offline fallback gestito dallo yield iniziale
    }
  }

  // --- COMMON (FUTURE CON CACHE OFFLINE-FALLBACK) ---

  Future<List<CastMember>> fetchCast(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse(
      '$_baseUrl/$endpoint/$id/credits?language=$_language',
    );
    final cacheKey = 'tmdb_cast_${id}_$endpoint';
    final cacheBox = Hive.box('tmdb_cache');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List castList = data['cast'] ?? [];

        // Salva in cache
        await cacheBox.put(cacheKey, castList);

        return castList
            .map((json) => CastMember.fromJson(json))
            .take(10)
            .toList();
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      // OFFLINE FALLBACK
      final cachedData = cacheBox.get(cacheKey);
      if (cachedData is List) {
        return cachedData
            .map((json) => CastMember.fromJson(Map<String, dynamic>.from(json)))
            .take(10)
            .toList();
      }
      throw Exception('Errore connessione e nessuna cache: $e');
    }
  }

  Future<List<Review>> fetchReviews(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse(
      '$_baseUrl/$endpoint/$id/reviews?language=$_language&page=1',
    );
    final cacheKey = 'tmdb_reviews_${id}_$endpoint';
    final cacheBox = Hive.box('tmdb_cache');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        // Salva in cache
        await cacheBox.put(cacheKey, results);

        return results.map((json) => Review.fromJson(json)).take(5).toList();
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      // OFFLINE FALLBACK
      final cachedData = cacheBox.get(cacheKey);
      if (cachedData is List) {
        return cachedData
            .map((json) => Review.fromJson(Map<String, dynamic>.from(json)))
            .take(5)
            .toList();
      }
      throw Exception('Errore connessione e nessuna cache: $e');
    }
  }

  Future<String?> fetchTrailerKey(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse('$_baseUrl/$endpoint/$id/videos?language=$_language');
    final cacheKey = 'tmdb_trailer_${id}_$endpoint';
    final cacheBox = Hive.box('tmdb_cache');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];

        // Salva la lista intera in cache
        await cacheBox.put(cacheKey, results);

        final trailer = results.firstWhere(
          (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer',
          orElse: () => null,
        );
        return trailer?['key'];
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      // OFFLINE FALLBACK
      final cachedData = cacheBox.get(cacheKey);
      if (cachedData is List) {
        final List results = cachedData;
        final trailer = results.firstWhere(
          (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer',
          orElse: () => null,
        );
        return trailer?['key'];
      }
      throw Exception('Errore connessione e nessuna cache: $e');
    }
  }

  Future<WatchProvidersResult?> fetchWatchProviders(
    int id, {
    bool isTv = false,
  }) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse('$_baseUrl/$endpoint/$id/watch/providers');
    final cacheKey = 'tmdb_providers_${id}_$endpoint';
    final cacheBox = Hive.box('tmdb_cache');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];

        // Salva in cache il nodo 'results'
        if (results != null) {
          await cacheBox.put(cacheKey, results);
          if (results.containsKey('IT')) {
            return WatchProvidersResult.fromJson(results['IT']);
          }
        }
        return null;
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      // OFFLINE FALLBACK
      final cachedData = cacheBox.get(cacheKey);
      if (cachedData is Map && cachedData.containsKey('IT')) {
        return WatchProvidersResult.fromJson(
          Map<String, dynamic>.from(cachedData['IT']),
        );
      }
      return null; // Fallback silenzioso per i providers
    }
  }

  // --- PERSON/ACTOR DETAILS CORRETTO (FUTURE CON CACHE) ---
  Future<Map<String, dynamic>> getPersonDetails(int personId) async {
    final url = Uri.parse(
      '$_baseUrl/person/$personId?language=$_language&append_to_response=combined_credits',
    );
    final cacheKey = 'tmdb_person_details_$personId';
    final cacheBox = Hive.box('tmdb_cache');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Salva l'intero oggetto in cache
        await cacheBox.put(cacheKey, data);

        return data;
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      // OFFLINE FALLBACK
      final cachedData = cacheBox.get(cacheKey);
      if (cachedData is Map) {
        return Map<String, dynamic>.from(cachedData);
      }
      throw Exception('Errore di Rete TMDB (Person) e nessuna cache: $e');
    }
  }

  // --- HELPERS ---
  Stream<List<Movie>> _streamMovies(Uri url, String cacheKey) async* {
    final cacheBox = Hive.box('tmdb_cache');
    final cachedResults = _readCachedResults(cacheBox, cacheKey);
    if (cachedResults != null) {
      yield cachedResults.map(Movie.fromTmdb).toList();
    }

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await cacheBox.put(cacheKey, results);
        yield results.map(Movie.fromTmdb).toList();
      }
    } catch (_) {
      // Offline fallback gestito dallo yield iniziale
    }
  }

  Stream<List<TvSeries>> _streamTvSeries(Uri url, String cacheKey) async* {
    final cacheBox = Hive.box('tmdb_cache');
    final cachedResults = _readCachedResults(cacheBox, cacheKey);
    if (cachedResults != null) {
      yield cachedResults.map(TvSeries.fromTmdb).toList();
    }

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await cacheBox.put(cacheKey, results);
        yield results.map(TvSeries.fromTmdb).toList();
      }
    } catch (_) {
      // Offline fallback gestito dallo yield iniziale
    }
  }

  List<Map<String, dynamic>>? _readCachedResults(
    Box cacheBox,
    String cacheKey,
  ) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! List) return null;

    return cached
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String _sanitizeCachePart(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  CastMember _mapPersonSearchResult(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sconosciuto',
      character: json['known_for_department'] ?? 'Attore',
      profilePath: json['profile_path'],
    );
  }
}
