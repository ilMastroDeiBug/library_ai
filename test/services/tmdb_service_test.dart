import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// IMPORT DELLA TUA APP
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import 'package:library_ai/injection_container.dart';

// 1. Finti Client e Servizi
class MockHttpClient extends Mock implements http.Client {}

class MockLanguageService extends Mock implements LanguageService {}

void main() {
  late TmdbService tmdbService;
  late MockHttpClient mockHttpClient;
  late MockLanguageService mockLanguageService;

  // SETUP ALL: Serve a mocktail per capire come "fingere" i tipi complessi come Uri
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://dummy.com'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockLanguageService = MockLanguageService();

    // 2. ISTRUZIONI PER IL FINTO LANGUAGE SERVICE
    // Quando il TmdbService chiede la lingua, rispondi sempre 'it-IT'
    when(() => mockLanguageService.currentLanguage).thenReturn('it-IT');

    // 3. REGISTRAZIONE IN GET_IT
    // Inseriamo il finto servizio in sl() così il TmdbService lo trova!
    sl.registerSingleton<LanguageService>(mockLanguageService);

    // 4. INIEZIONE DELLA DIPENDENZA HTTP
    tmdbService = TmdbService(client: mockHttpClient);
  });

  tearDown(() {
    // IMPORTANTE: Puliamo il Service Locator (get_it) dopo ogni test
    // per non "sporcare" i test successivi
    sl.reset();
  });

  group('Valanga di Test: TMDB Service', () {
    // Un finto JSON un po' più completo per evitare che Movie.fromTmdb fallisca
    final tJsonResponse = jsonEncode({
      "results": [
        {
          "id": 1,
          "title": "Inception",
          "poster_path": "/img.jpg",
          "overview": "Sogno",
          "release_date": "2010-07-15",
          "vote_average": 8.8,
          "genre_ids": [28, 878],
        },
        {
          "id": 2,
          "title": "Interstellar",
          "poster_path": "/img2.jpg",
          "overview": "Spazio",
          "release_date": "2014-11-05",
          "vote_average": 8.6,
          "genre_ids": [12, 878],
        },
      ],
    });

    test(
      '4. Fetch Trending Movies: deve restituire una lista di Movie se HTTP 200',
      () async {
        // ARRANGE
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response(tJsonResponse, 200));

        // ACT (Usa fetchTrendingMovies, non getTrendingMovies)
        final movies = await tmdbService.fetchTrendingMovies();

        // ASSERT
        expect(movies, isA<List<Movie>>());
        expect(movies.length, 2);
        expect(movies.first.title, "Inception");

        // Assicurati che HTTP sia stato chiamato 1 sola volta
        verify(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).called(1);
      },
    );

    test(
      '5. Fetch Trending Movies: deve lanciare un errore se HTTP 404',
      () async {
        // ARRANGE
        when(
          () => mockHttpClient.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        // ACT & ASSERT
        expect(
          () async => await tmdbService.fetchTrendingMovies(),
          throwsException,
        );
      },
    );
  });
}
