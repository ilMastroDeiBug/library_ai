import 'dart:convert';
import '../../models/movie_widget/review_model.dart';
import 'package:http/http.dart' as http;
import '../../models/movie_widget/cast_model.dart';
import '/models/movie_widget/movie_model.dart';

class TmdbService {
  // Il tuo Read Access Token
  static const String _accessToken =
      "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0NmU3NmMyMGZiZjE2ZDFjYTMxZGM1NWM0YjQ5MTA4YyIsIm5iZiI6MTc3MDkxNjMzMC42MjEsInN1YiI6IjY5OGUwOWVhN2M5ZjE4Y2M2NGRjZGQ2NSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.LJL0sBW1eiY3GEw81O-RyD2L-DXqbl7sCwVPxEisabE";

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // Header per l'autenticazione
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json;charset=utf-8',
  };

  // 1. Cerca Film e Serie TV
  Future<List<Movie>> searchMedia(String query) async {
    if (query.isEmpty) return [];
    final url = Uri.parse(
      '$_baseUrl/search/multi?query=$query&language=it-IT&include_adult=false',
    );
    return _fetchFromUrl(url);
  }

  // 2. Prendi Film per Categoria (Azione, Popolari, etc.)
  // Per gli ID delle categorie: 28 = Azione, 12 = Avventura, 878 = Sci-Fi
  Future<List<Movie>> fetchByCategory(String categoryPath) async {
    final url = Uri.parse('$_baseUrl/$categoryPath?language=it-IT&page=1');
    return _fetchFromUrl(url);
  }

  // Motore interno di fetching
  Future<List<Movie>> _fetchFromUrl(Uri url) async {
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        return results
            .where(
              (item) => item['media_type'] != 'person',
            ) // Filtriamo via gli attori
            .map((item) => Movie.fromJson(item))
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
    // Usa _fetchFromUrl se è generico, oppure fai la chiamata qui:
    try {
      final response = await http.get(
        url,
        headers: _headers,
      ); // Usa i tuoi header auth
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List castList = data['cast'];
        return castList
            .map((json) => CastMember.fromJson(json))
            .take(10)
            .toList(); // Prendiamo i primi 10
      }
      return [];
    } catch (e) {
      print("Errore Cast: $e");
      return [];
    }
  }

  Future<List<Review>> fetchMovieReviews(int movieId) async {
    // Usiamo en-US perché le reviews italiane su TMDB sono rare
    final url = Uri.parse(
      '$_baseUrl/movie/$movieId/reviews?language=en-US&page=1',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        return results
            .map((json) => Review.fromJson(json))
            .take(5) // Limitiamo a 5 per pulizia UI
            .toList();
      }
      return [];
    } catch (e) {
      print("Errore Reviews: $e");
      return [];
    }
  }
}
