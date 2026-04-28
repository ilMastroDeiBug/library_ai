import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/book_repository.dart';
import 'package:library_ai/domain/repositories/explore_repository.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/explore_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/models/app_mode.dart';
import 'package:library_ai/domain/entities/category.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/watch_provider_model.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

class MockBookRepository extends Mock implements BookRepository {}

class MockExploreRepository extends Mock implements ExploreRepository {}

void main() {
  late MockMovieRepository movieRepo;
  late MockBookRepository bookRepo;
  late MockExploreRepository exploreRepo;

  setUp(() {
    movieRepo = MockMovieRepository();
    bookRepo = MockBookRepository();
    exploreRepo = MockExploreRepository();
  });

  group('Movie use cases bulk forwarding', () {
    test('ToggleMovieStatusUseCase toggles watched -> towatch', () async {
      when(
        () => movieRepo.updateStatus('u1', 1, 'towatch'),
      ).thenAnswer((_) async {});
      final useCase = ToggleMovieStatusUseCase(movieRepo);

      final newStatus = await useCase.call('u1', 1, 'watched');

      expect(newStatus, 'towatch');
      verify(() => movieRepo.updateStatus('u1', 1, 'towatch')).called(1);
    });

    test('ToggleMovieStatusUseCase toggles other -> watched', () async {
      when(
        () => movieRepo.updateStatus('u1', 1, 'watched'),
      ).thenAnswer((_) async {});
      final useCase = ToggleMovieStatusUseCase(movieRepo);

      final newStatus = await useCase.call('u1', 1, 'none');

      expect(newStatus, 'watched');
      verify(() => movieRepo.updateStatus('u1', 1, 'watched')).called(1);
    });

    test('GetMovieReviewsUseCase enforces isTv false', () async {
      when(() => movieRepo.getReviews(7, isTv: false)).thenAnswer(
        (_) async => [
          Review(author: 'a', content: 'c', createdAt: '2020-01-01'),
        ],
      );
      final useCase = GetMovieReviewsUseCase(movieRepo);

      final list = await useCase.call(7);
      expect(list.length, 1);
      verify(() => movieRepo.getReviews(7, isTv: false)).called(1);
    });

    test('GetMovieTrailerUseCase enforces isTv false', () async {
      when(
        () => movieRepo.getTrailerKey(9, isTv: false),
      ).thenAnswer((_) async => 'abc');
      final useCase = GetMovieTrailerUseCase(movieRepo);

      final key = await useCase.call(9);
      expect(key, 'abc');
      verify(() => movieRepo.getTrailerKey(9, isTv: false)).called(1);
    });

    test('GetMovieWatchProvidersUseCase enforces isTv false', () async {
      when(
        () => movieRepo.getWatchProviders(10, isTv: false),
      ).thenAnswer((_) async => WatchProvidersResult.empty());
      final useCase = GetMovieWatchProvidersUseCase(movieRepo);

      final providers = await useCase.call(10);
      expect(providers?.flatrate, isEmpty);
      verify(() => movieRepo.getWatchProviders(10, isTv: false)).called(1);
    });

    for (var i = 0; i < 40; i++) {
      test('GetSingleMovieUseCase parses id #$i', () async {
        when(
          () => movieRepo.getSingleMediaStream('u', i),
        ).thenAnswer((_) => Stream.value({'id': i}));
        final useCase = GetSingleMovieUseCase(movieRepo);

        final value = await useCase.call('u', '$i').first;

        expect((value as Map)['id'], i);
        verify(() => movieRepo.getSingleMediaStream('u', i)).called(1);
      });
    }
  });

  group('TV use cases bulk forwarding', () {
    test('GetTvSeriesReviewsUseCase enforces isTv true', () async {
      when(
        () => movieRepo.getReviews(1, isTv: true),
      ).thenAnswer((_) async => []);
      final useCase = GetTvSeriesReviewsUseCase(movieRepo);
      await useCase.call(1);
      verify(() => movieRepo.getReviews(1, isTv: true)).called(1);
    });

    test('GetTvSeriesCastUseCase enforces isTv true', () async {
      when(() => movieRepo.getCast(2, isTv: true)).thenAnswer((_) async => []);
      final useCase = GetTvSeriesCastUseCase(movieRepo);
      await useCase.call(2);
      verify(() => movieRepo.getCast(2, isTv: true)).called(1);
    });

    test('GetTvSeriesTrailerUseCase enforces isTv true', () async {
      when(
        () => movieRepo.getTrailerKey(3, isTv: true),
      ).thenAnswer((_) async => null);
      final useCase = GetTvSeriesTrailerUseCase(movieRepo);
      await useCase.call(3);
      verify(() => movieRepo.getTrailerKey(3, isTv: true)).called(1);
    });

    test('ToggleTvSeriesStatusUseCase toggles correctly', () async {
      when(
        () => movieRepo.updateStatus('u1', 99, 'watched'),
      ).thenAnswer((_) async {});
      final useCase = ToggleTvSeriesStatusUseCase(movieRepo);
      final status = await useCase.call('u1', 99, 'towatch');

      expect(status, 'watched');
      verify(() => movieRepo.updateStatus('u1', 99, 'watched')).called(1);
    });

    for (var i = 0; i < 40; i++) {
      test('GetSingleTvSeriesUseCase parses id #$i', () async {
        when(() => movieRepo.getSingleMediaStream('u', i)).thenAnswer(
          (_) => Stream.value(
            TvSeries(
              id: i,
              name: 'n$i',
              overview: '',
              posterPath: '',
              backdropPath: '',
              voteAverage: 0,
              voteCount: 0,
              firstAirDate: '',
            ),
          ),
        );

        final useCase = GetSingleTvSeriesUseCase(movieRepo);
        final tv = await useCase.call('u', '$i').first as TvSeries;

        expect(tv.id, i);
        verify(() => movieRepo.getSingleMediaStream('u', i)).called(1);
      });
    }
  });

  group('Book + Explore use cases bulk forwarding', () {
    test('ToggleBookStatusUseCase read -> toread', () async {
      when(
        () => bookRepo.updateBookStatus('u', 'b1', 'toread'),
      ).thenAnswer((_) async {});
      final useCase = ToggleBookStatusUseCase(bookRepo);

      final status = await useCase.call('u', 'b1', 'read');
      expect(status, 'toread');
      verify(() => bookRepo.updateBookStatus('u', 'b1', 'toread')).called(1);
    });

    test('ToggleBookStatusUseCase toread -> read', () async {
      when(
        () => bookRepo.updateBookStatus('u', 'b2', 'read'),
      ).thenAnswer((_) async {});
      final useCase = ToggleBookStatusUseCase(bookRepo);

      final status = await useCase.call('u', 'b2', 'toread');
      expect(status, 'read');
      verify(() => bookRepo.updateBookStatus('u', 'b2', 'read')).called(1);
    });

    test('GetExploreCategoriesUseCase forwards tv flag', () {
      when(
        () => exploreRepo.getCategoriesByMode(AppMode.movies, isTvSeries: true),
      ).thenReturn([
        const CategoryEntity(id: '1', name: 'Action', icon: Icons.movie),
      ]);

      final useCase = GetExploreCategoriesUseCase(exploreRepo);
      final categories = useCase.call(AppMode.movies, isTvSeries: true);

      expect(categories.length, 1);
      verify(
        () => exploreRepo.getCategoriesByMode(AppMode.movies, isTvSeries: true),
      ).called(1);
    });

    for (var i = 0; i < 30; i++) {
      test('Add/Delete/GetFullBookDetails forwarding #$i', () async {
        final b = Book(id: 'b$i', title: 't$i', author: 'a$i');
        when(() => bookRepo.addBook(b, 'u$i')).thenAnswer((_) async {});
        when(() => bookRepo.deleteBook('u$i', 'b$i')).thenAnswer((_) async {});
        when(() => bookRepo.getBookDetails(b)).thenAnswer((_) async => b);

        final addUseCase = AddBookUseCase(bookRepo);
        final deleteUseCase = DeleteBookUseCase(bookRepo);
        final detailUseCase = GetFullBookDetailsUseCase(bookRepo);

        await addUseCase.call(b, 'u$i');
        await deleteUseCase.call('u$i', 'b$i');
        final detailed = await detailUseCase.call(b);

        expect(detailed.id, 'b$i');
        verify(() => bookRepo.addBook(b, 'u$i')).called(1);
        verify(() => bookRepo.deleteBook('u$i', 'b$i')).called(1);
        verify(() => bookRepo.getBookDetails(b)).called(1);
      });
    }

    for (var i = 0; i < 20; i++) {
      test('Search/GetBooksByCategory forwarding #$i', () async {
        when(() => bookRepo.searchBooks('query$i')).thenAnswer((_) async => []);
        when(
          () => bookRepo.getBooksByCategory('cat$i'),
        ).thenAnswer((_) async => []);

        final searchUseCase = SearchBooksUseCase(bookRepo);
        final byCategoryUseCase = GetBooksByCategoryUseCase(bookRepo);

        await searchUseCase.call('query$i');
        await byCategoryUseCase.call('cat$i');

        verify(() => bookRepo.searchBooks('query$i')).called(1);
        verify(() => bookRepo.getBooksByCategory('cat$i')).called(1);
      });
    }

    for (var i = 0; i < 20; i++) {
      test('Movie search/category/save forwarding #$i', () async {
        when(() => movieRepo.searchMovies('m$i')).thenAnswer((_) async => []);
        when(
          () => movieRepo.getMoviesByCategory('popular', page: i + 1),
        ).thenAnswer((_) async => []);

        final movie = Movie(
          id: i,
          title: 'm$i',
          overview: '',
          posterPath: '',
          backdropPath: '',
          voteAverage: 0,
          voteCount: 0,
          releaseDate: '',
        );

        when(() => movieRepo.saveMovie(movie, 'u')).thenAnswer((_) async {});

        final searchUseCase = SearchMoviesUseCase(movieRepo);
        final byCategoryUseCase = GetMoviesByCategoryUseCase(movieRepo);
        final saveUseCase = SaveMovieUseCase(movieRepo);

        await searchUseCase.call('m$i');
        await byCategoryUseCase.call('popular', page: i + 1);
        await saveUseCase.call(movie, 'u');

        verify(() => movieRepo.searchMovies('m$i')).called(1);
        verify(
          () => movieRepo.getMoviesByCategory('popular', page: i + 1),
        ).called(1);
        verify(() => movieRepo.saveMovie(movie, 'u')).called(1);
      });
    }
  });
}
