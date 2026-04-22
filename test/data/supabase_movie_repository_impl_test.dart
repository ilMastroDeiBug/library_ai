import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/data/supabase_movie_repository_impl.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockTmdbService extends Mock implements TmdbService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockTmdbService tmdb;
  late SupabaseMovieRepositoryImpl repository;

  setUp(() {
    tmdb = MockTmdbService();
    repository = SupabaseMovieRepositoryImpl(
      supabaseClient: MockSupabaseClient(),
      tmdbService: tmdb,
    );
  });

  group('SupabaseMovieRepositoryImpl - routing category', () {
    test('movies: trending route uses fetchTrendingMovies', () async {
      when(() => tmdb.fetchTrendingMovies(page: 2)).thenAnswer(
        (_) async => [
          Movie(
            id: 1,
            title: 'A',
            overview: '',
            posterPath: '/p.jpg',
            backdropPath: '',
            voteAverage: 7,
            voteCount: 10,
            releaseDate: '2020',
          ),
        ],
      );

      final result = await repository.getMoviesByCategory('trending', page: 2);

      expect(result, hasLength(1));
      verify(() => tmdb.fetchTrendingMovies(page: 2)).called(1);
      verifyNever(
        () => tmdb.fetchMoviesByCategory(any(), page: any(named: 'page')),
      );
    });

    test('movies: genre route uses fetchMoviesByGenre', () async {
      when(() => tmdb.fetchMoviesByGenre('878', page: 1)).thenAnswer(
        (_) async => [
          Movie(
            id: 2,
            title: 'B',
            overview: '',
            posterPath: '/p.jpg',
            backdropPath: '',
            voteAverage: 7,
            voteCount: 10,
            releaseDate: '2021',
          ),
        ],
      );

      final result = await repository.getMoviesByCategory('with_genres=878');

      expect(result.first.id, 2);
      verify(() => tmdb.fetchMoviesByGenre('878', page: 1)).called(1);
    });

    test('movies: default route uses fetchMoviesByCategory', () async {
      when(() => tmdb.fetchMoviesByCategory('popular', page: 3)).thenAnswer(
        (_) async => [
          Movie(
            id: 3,
            title: 'C',
            overview: '',
            posterPath: '/p.jpg',
            backdropPath: '',
            voteAverage: 7,
            voteCount: 10,
            releaseDate: '2022',
          ),
        ],
      );

      final result = await repository.getMoviesByCategory('popular', page: 3);

      expect(result.first.id, 3);
      verify(() => tmdb.fetchMoviesByCategory('popular', page: 3)).called(1);
    });
  });

  group('SupabaseMovieRepositoryImpl - business filters', () {
    test('movies: filters out empty poster or zero voteCount', () async {
      when(() => tmdb.fetchMoviesByCategory('popular', page: 1)).thenAnswer(
        (_) async => [
          Movie(
            id: 1,
            title: 'ok',
            overview: '',
            posterPath: '/ok.jpg',
            backdropPath: '',
            voteAverage: 7,
            voteCount: 100,
            releaseDate: '2020',
          ),
          Movie(
            id: 2,
            title: 'no-poster',
            overview: '',
            posterPath: '',
            backdropPath: '',
            voteAverage: 7,
            voteCount: 100,
            releaseDate: '2020',
          ),
          Movie(
            id: 3,
            title: 'no-votes',
            overview: '',
            posterPath: '/x.jpg',
            backdropPath: '',
            voteAverage: 7,
            voteCount: 0,
            releaseDate: '2020',
          ),
        ],
      );

      final result = await repository.getMoviesByCategory('popular');

      expect(result.map((m) => m.id).toList(), [1]);
    });

    test('tv: filters out empty poster or zero voteCount', () async {
      when(() => tmdb.fetchTvSeriesByCategory('popular', page: 1)).thenAnswer(
        (_) async => [
          TvSeries(
            id: 11,
            name: 'ok',
            overview: '',
            posterPath: '/ok.jpg',
            backdropPath: '',
            voteAverage: 8,
            voteCount: 50,
            firstAirDate: '2021',
          ),
          TvSeries(
            id: 12,
            name: 'no-poster',
            overview: '',
            posterPath: '',
            backdropPath: '',
            voteAverage: 8,
            voteCount: 50,
            firstAirDate: '2021',
          ),
          TvSeries(
            id: 13,
            name: 'no-votes',
            overview: '',
            posterPath: '/x.jpg',
            backdropPath: '',
            voteAverage: 8,
            voteCount: 0,
            firstAirDate: '2021',
          ),
        ],
      );

      final result = await repository.getTvSeriesByCategory('popular');

      expect(result.map((tv) => tv.id).toList(), [11]);
    });
  });
}
