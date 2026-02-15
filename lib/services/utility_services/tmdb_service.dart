import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/injection_container.dart';
import '../../models/movie_widget/review_model.dart';
import '../../models/movie_widget/cast_model.dart';
import '../utility_services/language_service.dart';

class TmdbService {
  static const String _accessToken =
      "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0NmU3NmMyMGZiZjE2ZDFjYTMxZGM1NWM0YjQ5MTA4YyIsIm5iZiI6MTc3MDkxNjMzMC42MjEsInN1YiI6IjY5OGUwOWVhN2M5ZjE4Y2M2NGRjZGQ2NSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.LJL0sBW1eiY3GEw81O-RyD2L-DXqbl7sCwVPxEisabE";
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

  // --- FILM ---
  Future<List<Movie>> fetchMoviesByCategory(String endpoint) async {
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse('$_baseUrl/movie/$endpoint?language=$lang&page=1');
    return _fetchMovies(url);
  }

  Future<List<Movie>> fetchMoviesByGenre(String genreId) async {
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse(
      '$_baseUrl/discover/movie?with_genres=$genreId&language=$lang&page=1',
    );
    return _fetchMovies(url);
  }

  Future<List<Movie>> fetchTrendingMovies() async {
    final url = Uri.parse('$_baseUrl/trending/movie/week?language=it-IT');
    return _fetchMovies(url);
  }

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse(
      '$_baseUrl/search/movie?query=$query&language=$lang&include_adult=false',
    );
    return _fetchMovies(url);
  }

  // --- SERIE TV ---
  Future<List<TvSeries>> fetchTvSeriesByCategory(String endpoint) async {
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse('$_baseUrl/tv/$endpoint?language=$lang&page=1');
    return _fetchTvSeries(url);
  }

  Future<List<TvSeries>> fetchTvByGenre(String genreId) async {
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse(
      '$_baseUrl/discover/tv?with_genres=$genreId&language=$lang&page=1',
    );
    return _fetchTvSeries(url);
  }

  Future<List<TvSeries>> fetchTvTrending() async {
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse('$_baseUrl/trending/tv/week?language=$lang');
    return _fetchTvSeries(url);
  }

  Future<List<TvSeries>> searchTvSeries(String query) async {
    if (query.isEmpty) return [];
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse(
      '$_baseUrl/search/tv?query=$query&language=$lang&include_adult=false',
    );
    return _fetchTvSeries(url);
  }

  // --- COMMON ---
  Future<List<CastMember>> fetchCast(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final lang = sl<LanguageService>().currentLanguage;
    final url = Uri.parse('$_baseUrl/$endpoint/$id/credits?language=$lang');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List castList = data['cast'] ?? [];
        return castList
            .map((json) => CastMember.fromJson(json))
            .take(10)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Review>> fetchReviews(int id, {bool isTv = false}) async {
    final endpoint = isTv ? 'tv' : 'movie';
    final url = Uri.parse(
      '$_baseUrl/$endpoint/$id/reviews?language=en-US&page=1',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Review.fromJson(json)).take(5).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- HELPERS ---
  Future<List<Movie>> _fetchMovies(Uri url) async {
    try {
      print('🌐 Request Movie: $url');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((item) => Movie.fromTmdb(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<TvSeries>> _fetchTvSeries(Uri url) async {
    try {
      print('🌐 Request TV: $url');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((item) => TvSeries.fromTmdb(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
