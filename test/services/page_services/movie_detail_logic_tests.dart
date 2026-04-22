import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/services/pages_services/movie_detail_logic.dart';
import 'package:library_ai/services/utility_services/ai_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSaveMovieUseCase extends Mock implements SaveMovieUseCase {}

class MockSaveTvSeriesUseCase extends Mock implements SaveTvSeriesUseCase {}

class MockAIService extends Mock implements AIService {}

class FakeMovie extends Fake implements Movie {}

class FakeTvSeries extends Fake implements TvSeries {}

void main() {
  late MockAuthRepository authRepository;
  late MockSaveMovieUseCase saveMovieUseCase;
  late MockSaveTvSeriesUseCase saveTvSeriesUseCase;
  late MockAIService aiService;
  late MovieDetailLogic logic;

  setUpAll(() {
    registerFallbackValue(FakeMovie());
    registerFallbackValue(FakeTvSeries());
  });

  setUp(() async {
    await sl.reset();
    authRepository = MockAuthRepository();
    saveMovieUseCase = MockSaveMovieUseCase();
    saveTvSeriesUseCase = MockSaveTvSeriesUseCase();
    aiService = MockAIService();
    logic = MovieDetailLogic(aiService: aiService);

    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<SaveMovieUseCase>(saveMovieUseCase);
    sl.registerSingleton<SaveTvSeriesUseCase>(saveTvSeriesUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  Movie buildMovie({String status = 'none'}) => Movie(
    id: 1,
    title: 'Movie',
    overview: 'overview',
    posterPath: '/p.jpg',
    backdropPath: '/b.jpg',
    voteAverage: 7,
    voteCount: 100,
    releaseDate: '2020-01-01',
    status: status,
  );

  TvSeries buildSeries({String status = 'none'}) => TvSeries(
    id: 2,
    name: 'Series',
    overview: 'overview',
    posterPath: '/p.jpg',
    backdropPath: '/b.jpg',
    voteAverage: 7,
    voteCount: 100,
    firstAirDate: '2020-01-01',
    status: status,
  );

  group('MovieDetailLogic.handleStatusAction', () {
    testWidgets('shows login snackbar when user is null', (tester) async {
      when(() => authRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildMovie(), 'watched', 'none');
      await tester.pump();

      expect(find.text('Accedi per salvare.'), findsOneWidget);
      verifyNever(() => saveMovieUseCase.call(any(), any()));
      verifyNever(() => saveTvSeriesUseCase.call(any(), any()));
    });

    testWidgets('saves movie with toggled status', (tester) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(() => saveMovieUseCase.call(any(), 'u1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildMovie(), 'watched', 'none');
      await tester.pump();

      final captured =
          verify(() => saveMovieUseCase.call(captureAny(), 'u1')).captured.first
              as Movie;
      expect(captured.status, 'watched');
      expect(find.text('Segnato come Visto'), findsOneWidget);
    });

    testWidgets('removes movie status when action already active', (
      tester,
    ) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(() => saveMovieUseCase.call(any(), 'u1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(
        context,
        buildMovie(status: 'watched'),
        'watched',
        'watched',
      );
      await tester.pump();

      final captured =
          verify(() => saveMovieUseCase.call(captureAny(), 'u1')).captured.first
              as Movie;
      expect(captured.status, 'none');
      expect(find.text('Rimosso dalla Watchlist'), findsOneWidget);
    });

    testWidgets('saves tv series with toggled status', (tester) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(
        () => saveTvSeriesUseCase.call(any(), 'u1'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildSeries(), 'towatch', 'none');
      await tester.pump();

      final captured =
          verify(
                () => saveTvSeriesUseCase.call(captureAny(), 'u1'),
              ).captured.first
              as TvSeries;
      expect(captured.status, 'towatch');
      expect(find.text('Aggiunto ai Da Vedere'), findsOneWidget);
    });

    testWidgets('shows error snackbar when save fails', (tester) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(
        () => saveMovieUseCase.call(any(), 'u1'),
      ).thenThrow(Exception('save failed'));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildMovie(), 'watched', 'none');
      await tester.pump();

      expect(find.text('Errore nel salvataggio. Riprova.'), findsOneWidget);
    });
  });

  group('MovieDetailLogic.handleAnalysis', () {
    testWidgets('returns null when user is null', (tester) async {
      when(() => authRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      final result = await logic.handleAnalysis(context, buildMovie());

      expect(result, isNull);
      verifyNever(() => saveMovieUseCase.call(any(), any()));
      verifyNever(() => saveTvSeriesUseCase.call(any(), any()));
    });

    testWidgets('saves movie analysis with SaveMovieUseCase on success', (
      tester,
    ) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(
        () => aiService.analyzeMedia(
          title: any(named: 'title'),
          type: any(named: 'type'),
          userProfile: any(named: 'userProfile'),
          creator: any(named: 'creator'),
        ),
      ).thenAnswer((_) async => 'analysis-movie');
      when(() => saveMovieUseCase.call(any(), 'u1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      final result = await logic.handleAnalysis(context, buildMovie());

      expect(result, 'analysis-movie');
      final captured =
          verify(() => saveMovieUseCase.call(captureAny(), 'u1')).captured.first
              as Movie;
      expect(captured.aiAnalysis, 'analysis-movie');
    });

    testWidgets('saves tv analysis with SaveTvSeriesUseCase on success', (
      tester,
    ) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(
        () => aiService.analyzeMedia(
          title: any(named: 'title'),
          type: any(named: 'type'),
          userProfile: any(named: 'userProfile'),
          creator: any(named: 'creator'),
        ),
      ).thenAnswer((_) async => 'analysis-tv');
      when(
        () => saveTvSeriesUseCase.call(any(), 'u1'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      final result = await logic.handleAnalysis(context, buildSeries());

      expect(result, 'analysis-tv');
      final captured =
          verify(
                () => saveTvSeriesUseCase.call(captureAny(), 'u1'),
              ).captured.first
              as TvSeries;
      expect(captured.aiAnalysis, 'analysis-tv');
    });
  });
}
