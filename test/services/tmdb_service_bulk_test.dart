import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockLanguageService extends Mock implements LanguageService {}

void main() {
  late TmdbService service;
  late MockHttpClient client;
  late MockLanguageService languageService;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    client = MockHttpClient();
    languageService = MockLanguageService();
    when(() => languageService.currentLanguage).thenReturn('it-IT');

    sl.registerSingleton<LanguageService>(languageService);
    service = TmdbService(client: client);
  });

  tearDown(() async {
    await sl.reset();
  });

  group('TmdbService url and parsing bulk tests', () {
    final movieResponse = jsonEncode({
      'results': [
        {
          'id': 1,
          'title': 'Title 1',
          'overview': 'Overview',
          'poster_path': '/poster.jpg',
          'backdrop_path': '/backdrop.jpg',
          'vote_average': 8.0,
          'vote_count': 100,
          'release_date': '2020-01-01',
        },
      ],
    });

    final tvResponse = jsonEncode({
      'results': [
        {
          'id': 2,
          'name': 'TV 1',
          'overview': 'Overview tv',
          'poster_path': '/poster_tv.jpg',
          'backdrop_path': '/backdrop_tv.jpg',
          'vote_average': 7.7,
          'vote_count': 77,
          'first_air_date': '2021-01-01',
        },
      ],
    });

    test('searchMovies returns [] for empty query without HTTP call', () async {
      final result = await service.searchMovies('');
      expect(result, isEmpty);
      verifyNever(() => client.get(any(), headers: any(named: 'headers')));
    });

    test(
      'searchTvSeries returns [] for empty query without HTTP call',
      () async {
        final result = await service.searchTvSeries('');
        expect(result, isEmpty);
        verifyNever(() => client.get(any(), headers: any(named: 'headers')));
      },
    );

    test('fetchCast returns max 10 members', () async {
      final cast = List.generate(
        15,
        (i) => {'name': 'n$i', 'character': 'c$i'},
      );
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode({'cast': cast}), 200));

      final result = await service.fetchCast(1);
      expect(result.length, 10);
    });

    test('fetchReviews returns max 5 items', () async {
      final reviews = List.generate(
        12,
        (i) => {
          'author': 'a$i',
          'content': 'c$i',
          'created_at': '2020-01-01',
          'author_details': {'rating': 5},
        },
      );

      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode({'results': reviews}), 200),
      );

      final result = await service.fetchReviews(1);
      expect(result.length, 5);
    });

    test('fetchTrailerKey returns trailer key when present', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'results': [
              {'site': 'Vimeo', 'type': 'Teaser', 'key': 'x'},
              {'site': 'YouTube', 'type': 'Trailer', 'key': 'target_key'},
            ],
          }),
          200,
        ),
      );

      final key = await service.fetchTrailerKey(1);
      expect(key, 'target_key');
    });

    test('fetchTrailerKey returns null when trailer missing', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode({'results': []}), 200),
      );

      final key = await service.fetchTrailerKey(1);
      expect(key, isNull);
    });

    test('fetchWatchProviders returns null when IT is missing', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'results': {'US': {}},
          }),
          200,
        ),
      );

      final providers = await service.fetchWatchProviders(1);
      expect(providers, isNull);
    });

    test('fetchWatchProviders parses IT result', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'results': {
              'IT': {
                'link': 'https://tmdb',
                'flatrate': [
                  {
                    'provider_name': 'Netflix',
                    'logo_path': '/logo.png',
                    'provider_id': 8,
                  },
                ],
              },
            },
          }),
          200,
        ),
      );

      final providers = await service.fetchWatchProviders(1);
      expect(providers, isNotNull);
      expect(providers!.flatrate.first.providerName, 'Netflix');
    });

    test('fetchTrendingMovies uses language and page in URL', () async {
      Uri? captured;
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((
        inv,
      ) async {
        captured = inv.positionalArguments.first as Uri;
        return http.Response(movieResponse, 200);
      });

      await service.fetchTrendingMovies(page: 3);

      expect(captured.toString(), contains('language=it-IT'));
      expect(captured.toString(), contains('page=3'));
      expect(captured.toString(), contains('/trending/movie/week'));
    });

    test('fetchTvTrending uses language and page in URL', () async {
      Uri? captured;
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer((
        inv,
      ) async {
        captured = inv.positionalArguments.first as Uri;
        return http.Response(tvResponse, 200);
      });

      await service.fetchTvTrending(page: 2);

      expect(captured.toString(), contains('language=it-IT'));
      expect(captured.toString(), contains('page=2'));
      expect(captured.toString(), contains('/trending/tv/week'));
    });

    for (var i = 0; i < 20; i++) {
      test('movie endpoint forwarding #$i', () async {
        Uri? captured;
        when(
          () => client.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((inv) async {
          captured = inv.positionalArguments.first as Uri;
          return http.Response(movieResponse, 200);
        });

        await service.fetchMoviesByCategory('popular', page: i + 1);

        expect(captured.toString(), contains('/movie/popular'));
        expect(captured.toString(), contains('page=${i + 1}'));
      });
    }

    for (var i = 0; i < 20; i++) {
      test('tv endpoint forwarding #$i', () async {
        Uri? captured;
        when(
          () => client.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((inv) async {
          captured = inv.positionalArguments.first as Uri;
          return http.Response(tvResponse, 200);
        });

        await service.fetchTvSeriesByCategory('popular', page: i + 1);

        expect(captured.toString(), contains('/tv/popular'));
        expect(captured.toString(), contains('page=${i + 1}'));
      });
    }

    final errorCases = <({String name, Future<dynamic> Function() run})>[
      (name: 'fetchTrendingMovies', run: () => service.fetchTrendingMovies()),
      (name: 'fetchMoviesByGenre', run: () => service.fetchMoviesByGenre('28')),
      (
        name: 'fetchMoviesByCategory',
        run: () => service.fetchMoviesByCategory('top_rated'),
      ),
      (name: 'fetchTvByGenre', run: () => service.fetchTvByGenre('16')),
      (name: 'fetchTvTrending', run: () => service.fetchTvTrending()),
      (
        name: 'fetchTvSeriesByCategory',
        run: () => service.fetchTvSeriesByCategory('top_rated'),
      ),
      (name: 'searchMovies', run: () => service.searchMovies('abc')),
      (name: 'searchTvSeries', run: () => service.searchTvSeries('abc')),
    ];

    for (final tc in errorCases) {
      test('throws exception on HTTP != 200 - ${tc.name}', () async {
        when(
          () => client.get(any(), headers: any(named: 'headers')),
        ).thenAnswer((_) async => http.Response('err', 500));

        expect(() async => await tc.run(), throwsException);
      });
    }

    test('fetchCast throws on HTTP != 200', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('err', 503));

      expect(() => service.fetchCast(10), throwsException);
    });

    test('fetchReviews throws on HTTP != 200', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('err', 503));

      expect(() => service.fetchReviews(10), throwsException);
    });

    test('fetchTrailerKey throws on HTTP != 200', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('err', 503));

      expect(() => service.fetchTrailerKey(10), throwsException);
    });

    test('fetchWatchProviders throws on HTTP != 200', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('err', 503));

      expect(() => service.fetchWatchProviders(10), throwsException);
    });

    test('fetchCast wraps network exception', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      expect(() => service.fetchCast(10), throwsException);
    });

    test('fetchReviews wraps network exception', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      expect(() => service.fetchReviews(10), throwsException);
    });

    test('fetchTrailerKey wraps network exception', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      expect(() => service.fetchTrailerKey(10), throwsException);
    });

    test('fetchWatchProviders wraps network exception', () async {
      when(
        () => client.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      expect(() => service.fetchWatchProviders(10), throwsException);
    });
  });
}
