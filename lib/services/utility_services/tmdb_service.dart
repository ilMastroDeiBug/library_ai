import 'dart:convert';
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

  // 1. DEPENDENCY INJECTION: Il client HTTP è ora iniettabile
  final http.Client _client;

  TmdbService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

  String get _language => sl<LanguageService>().currentLanguage;

  // --- FILM ---
  Future<List<Movie>> fetchMoviesByCategory(
    String endpoint, {
    int page = 1,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/movie/$endpoint?language=$_language&page=$page',
    );
    return _fetchMovies(url);
  }

  Future<List<Movie>> fetchMoviesByGenre(String genreId, {int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/discover/movie?with_genres=$genreId&language=$_language&page=$page',
    );
    return _fetchMovies(url);
  }

  Future<List<Movie>> fetchTrendingMovies({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/trending/movie/week?language=$_language&page=$page',
    );
    return _fetchMovies(url);
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    final url = Uri.parse(
      '$_baseUrl/search/movie?query=$query&language=$_language&include_adult=false&page=$page',
    );
    return _fetchMovies(url);
  }

  // --- SERIE TV ---
  Future<List<TvSeries>> fetchTvSeriesByCategory(
    String endpoint, {
    int page = 1,
  }) async {
    final url = Uri.parse('$_baseUrl/tv/$endpoint?language=$_language&page=$page');
    return _fetchTvSeries(url);
  }

  Future<List<TvSeries>> fetchTvByGenre(String genreId, {int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/discover/tv?with_genres=$genreId&language=$_language&page=$page',
    );
    return _fetchTvSeries(url);
  }

  Future<List<TvSeries>> fetchTvTrending({int page = 1}) async {
    final url = Uri.parse(
      '$_baseUrl/trending/tv/week?language=$_language&page=$page',
    );
    return _fetchTvSeries(url);
  }

  Future<List<TvSeries>> searchTvSeries(String query, {int page = 1}) async {
    if (query.isEmpty) return [];
    final url = Uri.parse(
      '$_baseUrl/search/tv?query=$query&language=$_language&include_adult=false&page=$page',
    );
    return _fetchTvSeries(url);
  }

  // --- COMMON (Cast, Reviews, Trailers, Providers) ---
  Future<List<CastMember>> fetchCast(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse('$_baseUrl/$endpoint/$id/credits?language=$_language');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List castList = data['cast'] ?? [];
        return castList
            .map((json) => CastMember.fromJson(json))
            .take(10)
            .toList();
      } else {
        // 2. LANCIO ECCEZIONE REALE
        throw Exception('Errore TMDB fetchCast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore connessione fetchCast: $e');
    }
  }

  Future<List<Review>> fetchReviews(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse(
      '$_baseUrl/$endpoint/$id/reviews?language=$_language&page=1',
    );

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Review.fromJson(json)).take(5).toList();
      } else {
        throw Exception('Errore TMDB fetchReviews: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore connessione fetchReviews: $e');
    }
  }

  Future<String?> fetchTrailerKey(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse('$_baseUrl/$endpoint/$id/videos?language=$_language');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        final trailer = results.firstWhere(
          (video) => video['site'] == 'YouTube' && video['type'] == 'Trailer',
          orElse: () => null,
        );
        if (trailer != null) {
          return trailer['key'];
        }
        return null;
      } else {
        throw Exception('Errore TMDB fetchTrailerKey: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore connessione fetchTrailerKey: $e');
    }
  }

  Future<WatchProvidersResult?> fetchWatchProviders(
    int id, {
    bool isTv = false,
  }) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse('$_baseUrl/$endpoint/$id/watch/providers');

    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];

        if (results != null && results.containsKey('IT')) {
          return WatchProvidersResult.fromJson(results['IT']);
        }
        return null;
      } else {
        throw Exception(
          'Errore TMDB fetchWatchProviders: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Errore connessione fetchWatchProviders: $e');
    }
  }

  // --- HELPERS ---
  Future<List<Movie>> _fetchMovies(Uri url) async {
    try {
      print('🌐 Request Movie: $url');
      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((item) => Movie.fromTmdb(item))
            .toList();
      } else {
        throw Exception('Errore HTTP TMDB (Movies): ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore di Rete TMDB (Movies): $e');
    }
  }

  Future<List<TvSeries>> _fetchTvSeries(Uri url) async {
    try {
      print('🌐 Request TV: $url');
      final response = await _client.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((item) => TvSeries.fromTmdb(item))
            .toList();
      } else {
        throw Exception('Errore HTTP TMDB (TV): ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore di Rete TMDB (TV): $e');
    }
  }
}
