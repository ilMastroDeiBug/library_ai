import 'dart:convert';
import 'package:http/http.dart' as http;
// IMPORTA L'ENTITY DEL DOMINIO
import 'package:library_ai/domain/entities/movie.dart';
import '../../models/movie_widget/review_model.dart';
import '../../models/movie_widget/cast_model.dart';

class TmdbService {
  static const String _accessToken =
      "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0NmU3NmMyMGZiZjE2ZDFjYTMxZGM1NWM0YjQ5MTA4YyIsIm5iZiI6MTc3MDkxNjMzMC42MjEsInN1YiI6IjY5OGUwOWVhN2M5ZjE4Y2M2NGRjZGQ2NSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.LJL0sBW1eiY3GEw81O-RyD2L-DXqbl7sCwVPxEisabE";
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

  // Restituisce List<Movie> (Domain Entity)
  Future<List<Movie>> fetchByCategory(String categoryPath) async {
    final url = Uri.parse('$_baseUrl/$categoryPath?language=it-IT&page=1');
    return _fetchFromUrl(url);
  }

  Future<List<Movie>> searchMedia(String query) async {
    if (query.isEmpty) return [];
    final url = Uri.parse(
      '$_baseUrl/search/multi?query=$query&language=it-IT&include_adult=false',
    );
    return _fetchFromUrl(url);
  }

  Future<List<Movie>> _fetchFromUrl(Uri url) async {
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        return results
            .where((item) => item['media_type'] != 'person')
            // Usa fromTmdb che abbiamo definito nell'Entity
            .map((item) => Movie.fromTmdb(item))
            .toList();
      } else {
        print("Errore TMDB: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Eccezione TMDB: $e");
      return [];
    }
  }

  Future<List<CastMember>> fetchMovieCast(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/credits?language=it-IT');
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List castList = data['cast'];
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

  Future<List<Review>> fetchMovieReviews(int movieId) async {
    final url = Uri.parse(
      '$_baseUrl/movie/$movieId/reviews?language=en-US&page=1',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        return results.map((json) => Review.fromJson(json)).take(5).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
