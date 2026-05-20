import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/entities/review.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/services/utility_services/cache_wrapper.dart';
import '../../models/movie_widget/cast_model.dart';
import '../../models/movie_widget/watch_provider_model.dart';
import '../utility_services/language_service.dart';

class TmdbService {
  static const String _accessToken =
      "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0NmU3NmMyMGZiZjE2ZDFjYTMxZGM1NWM0YjQ5MTA4YyIsIm5iZiI6MTc3MDkxNjMzMC42MjEsInN1YiI6IjY5OGUwOWVhN2M5ZjE4Y2M2NGRjZGQ2NSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.LJL0sBW1eiY3GEw81O-RyD2L-DXqbl7sCwVPxEisabE";
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const Duration _cacheTtl = Duration(hours: 24);

  final http.Client _client;

  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

  String get _language => sl<LanguageService>().currentLanguage;

  // --- FILM ---
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

  Future<Movie?> searchMovieByTitleAndYear(String title, [String? year]) async {
    String urlStr = '$_baseUrl/search/movie?query=${Uri.encodeQueryComponent(title)}&language=$_language&page=1';
    if (year != null && year.isNotEmpty) {
      urlStr += '&primary_release_year=$year';
    }
    
    try {
      final response = await _client.get(Uri.parse(urlStr), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return Movie.fromTmdb(Map<String, dynamic>.from(results.first));
        }
      }
    } catch (_) {}
    return null;
  }

  // --- SERIE TV ---
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

  Future<Movie> getMovieDetails(int movieId) async {
    final languageCode = sl<LanguageService>().currentLanguage;
    final response = await _client.get(
      Uri.parse('$_baseUrl/movie/$movieId?language=$languageCode'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Movie.fromTmdb(data);
    } else {
      throw Exception('Errore fetch dettagli movie: ${response.statusCode}');
    }
  }

  // --- FIX: RECUPERO DETTAGLI CON LE STAGIONI ---
  Future<TvSeries> getTvSeriesDetails(int seriesId) async {
    final languageCode = sl<LanguageService>().currentLanguage;
    // FIX: Niente $_apiKey, passiamo gli headers protetti di TmdbService
    final response = await _client.get(
      Uri.parse('$_baseUrl/tv/$seriesId?language=$languageCode'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      return TvSeries.fromTmdb(
        jsonMap,
      ); // Questo mappa correttamente le "seasons"
    } else {
      throw Exception(
        'Impossibile recuperare i dettagli della Serie TV da TMDB',
      );
    }
  }

  // --- ATTORI / PERSONE ---
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

    final cachedResults = await _readCachedResults(cacheBox, cacheKey);
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
        await _writeCache(cacheBox, cacheKey, results);
        yield results.map(_mapPersonSearchResult).toList();
      }
    } catch (_) {}
  }

  // --- COMMON ---
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
        await _writeCache(cacheBox, cacheKey, castList);
        return castList
            .map((json) => CastMember.fromJson(json))
            .take(10)
            .toList();
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      final cachedData = await _readCachedList(cacheBox, cacheKey);
      if (cachedData != null) {
        return cachedData
            .map((json) => CastMember.fromJson(Map<String, dynamic>.from(json)))
            .take(10)
            .toList();
      }
      throw Exception('Errore connessione: $e');
    }
  }

  Future<List<Review>> fetchReviews(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final cacheBox = Hive.box('tmdb_cache');
    final languages = <String>[_language, if (_language != 'en-US') 'en-US'];
    Object? lastError;

    for (final language in languages) {
      final cacheKey = 'tmdb_reviews_${id}_${endpoint}_$language';

      try {
        final results = await _fetchReviewRows(
          endpoint: endpoint,
          id: id,
          language: language,
          cacheBox: cacheBox,
          cacheKey: cacheKey,
        );

        if (results.isNotEmpty || language == languages.last) {
          return results.map(_mapTmdbReview).take(5).toList();
        }
      } catch (e) {
        lastError = e;
        final cachedData = await _readCachedList(cacheBox, cacheKey);
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData
              .whereType<Map>()
              .map((json) => _mapTmdbReview(Map<String, dynamic>.from(json)))
              .take(5)
              .toList();
        }
      }
    }

    if (lastError != null) {
      throw Exception('Errore connessione: $lastError');
    }
    return [];
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
        await _writeCache(cacheBox, cacheKey, results);
        final trailer = results.firstWhere(
          (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer',
          orElse: () => null,
        );
        return trailer?['key'];
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      final cachedData = await _readCachedList(cacheBox, cacheKey);
      if (cachedData != null) {
        final trailer = cachedData.firstWhere(
          (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer',
          orElse: () => null,
        );
        return trailer?['key'];
      }
      throw Exception('Errore connessione: $e');
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
        if (results != null) {
          await _writeCache(cacheBox, cacheKey, results);
          if (results.containsKey('IT')) {
            return WatchProvidersResult.fromJson(results['IT']);
          }
        }
        return null;
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      final cachedData = await _readCachedMap(cacheBox, cacheKey);
      if (cachedData != null && cachedData.containsKey('IT')) {
        return WatchProvidersResult.fromJson(
          Map<String, dynamic>.from(cachedData['IT']),
        );
      }
      return null;
    }
  }

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
        await _writeCache(cacheBox, cacheKey, data);
        return data;
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      final cachedData = await _readCachedMap(cacheBox, cacheKey);
      if (cachedData != null) return cachedData;
      throw Exception('Errore di Rete TMDB (Person): $e');
    }
  }

  // --- HELPERS ---

  Future<List<Map<String, dynamic>>> _fetchReviewRows({
    required String endpoint,
    required int id,
    required String language,
    required Box cacheBox,
    required String cacheKey,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/$endpoint/$id/reviews?language=$language&page=1',
    );
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Status code: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = (data['results'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    await _writeCache(cacheBox, cacheKey, results);
    return results;
  }

  Review _mapTmdbReview(Map<String, dynamic> json) {
    final rawAuthorDetails = json['author_details'];
    final authorDetails = rawAuthorDetails is Map
        ? Map<String, dynamic>.from(rawAuthorDetails)
        : null;
    double rating = 0.0;
    String? avatarUrl;

    if (authorDetails != null) {
      if (authorDetails['rating'] != null) {
        rating = (authorDetails['rating'] as num).toDouble() / 2;
      }
      if (authorDetails['avatar_path'] != null) {
        final path = authorDetails['avatar_path'].toString();
        if (path.startsWith('/http')) {
          avatarUrl = path.substring(1);
        } else if (path.startsWith('http')) {
          avatarUrl = path;
        } else if (path.startsWith('/')) {
          avatarUrl = 'https://image.tmdb.org/t/p/w200$path';
        }
      }
    }

    return Review(
      id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      author: json['author']?.toString() ?? 'Utente TMDB',
      content: json['content'] ?? '',
      rating: rating,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      avatarUrl: avatarUrl,
      isCustom: false,
    );
  }

  Stream<List<Movie>> _streamMovies(Uri url, String cacheKey) async* {
    final cacheBox = Hive.box('tmdb_cache');
    final cachedResults = await _readCachedResults(cacheBox, cacheKey);
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
        await _writeCache(cacheBox, cacheKey, results);
        yield results.map(Movie.fromTmdb).toList();
      }
    } catch (_) {}
  }

  Stream<List<TvSeries>> _streamTvSeries(Uri url, String cacheKey) async* {
    final cacheBox = Hive.box('tmdb_cache');
    final cachedResults = await _readCachedResults(cacheBox, cacheKey);
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
        await _writeCache(cacheBox, cacheKey, results);
        yield results.map(TvSeries.fromTmdb).toList();
      }
    } catch (_) {}
  }

  Future<void> _writeCache(Box cacheBox, String cacheKey, Object? data) {
    final wrapper = CacheWrapper<Object?>(data: data, cachedAt: DateTime.now());
    return cacheBox.put(cacheKey, wrapper.toHiveMap());
  }

  Future<Object?> _readFreshCachedValue(Box cacheBox, String cacheKey) async {
    final wrapper = CacheWrapper.fromHive<Object?>(cacheBox.get(cacheKey));
    if (wrapper == null) {
      if (cacheBox.containsKey(cacheKey)) await cacheBox.delete(cacheKey);
      return null;
    }
    if (wrapper.isExpired(_cacheTtl)) {
      await cacheBox.delete(cacheKey);
      return null;
    }
    return wrapper.data;
  }

  Future<List<dynamic>?> _readCachedList(Box cacheBox, String cacheKey) async {
    final cached = await _readFreshCachedValue(cacheBox, cacheKey);
    if (cached is! List) return null;
    return cached;
  }

  Future<Map<String, dynamic>?> _readCachedMap(
    Box cacheBox,
    String cacheKey,
  ) async {
    final cached = await _readFreshCachedValue(cacheBox, cacheKey);
    if (cached is! Map) return null;
    return Map<String, dynamic>.from(cached);
  }

  Future<List<Map<String, dynamic>>?> _readCachedResults(
    Box cacheBox,
    String cacheKey,
  ) async {
    final cached = await _readCachedList(cacheBox, cacheKey);
    if (cached is! List) return null;
    return cached
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String _sanitizeCachePart(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  CastMember _mapPersonSearchResult(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sconosciuto',
      character: json['known_for_department'] ?? 'Attore',
      profilePath: json['profile_path'],
    );
  }
}
