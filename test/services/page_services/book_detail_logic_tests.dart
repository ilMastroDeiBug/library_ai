import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/services/pages_services/book_detail_logic.dart';
import 'package:library_ai/services/utility_services/ai_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAddBookUseCase extends Mock implements AddBookUseCase {}

class MockDeleteBookUseCase extends Mock implements DeleteBookUseCase {}

class MockAIService extends Mock implements AIService {}

class FakeBook extends Fake implements Book {}

void main() {
  late MockAuthRepository authRepository;
  late MockAddBookUseCase addBookUseCase;
  late MockDeleteBookUseCase deleteBookUseCase;
  late MockAIService aiService;
  late BookDetailLogic logic;

  setUpAll(() {
    registerFallbackValue(FakeBook());
  });

  setUp(() async {
    await sl.reset();
    authRepository = MockAuthRepository();
    addBookUseCase = MockAddBookUseCase();
    deleteBookUseCase = MockDeleteBookUseCase();
    aiService = MockAIService();
    logic = BookDetailLogic(aiService: aiService);

    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<AddBookUseCase>(addBookUseCase);
    sl.registerSingleton<DeleteBookUseCase>(deleteBookUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  Book buildBook({String status = 'toread'}) => Book(
    id: 'b1',
    title: 'Book title',
    author: 'Author',
    status: status,
    description: 'desc',
  );

  group('BookDetailLogic.handleStatusAction', () {
    testWidgets('shows login snackbar when user is null', (tester) async {
      when(() => authRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildBook(), 'read', 'toread');
      await tester.pump();

      expect(find.text('Devi essere loggato'), findsOneWidget);
      verifyNever(() => addBookUseCase.call(any(), any()));
      verifyNever(() => deleteBookUseCase.call(any(), any()));
    });

    testWidgets('deletes when target status equals current status', (
      tester,
    ) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(() => deleteBookUseCase.call('u1', 'b1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildBook(), 'read', 'read');
      await tester.pump();

      verify(() => deleteBookUseCase.call('u1', 'b1')).called(1);
      expect(find.text('Rimosso dalla libreria'), findsOneWidget);
    });

    testWidgets('adds/updates with target status when different', (
      tester,
    ) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(() => addBookUseCase.call(any(), 'u1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildBook(), 'read', 'toread');
      await tester.pump();

      final captured =
          verify(() => addBookUseCase.call(captureAny(), 'u1')).captured.first
              as Book;
      expect(captured.status, 'read');
      expect(find.text('Segnato come letto'), findsOneWidget);
    });

    testWidgets('shows error snackbar when delete fails', (tester) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(
        () => deleteBookUseCase.call('u1', 'b1'),
      ).thenThrow(Exception('delete failed'));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildBook(), 'read', 'read');
      await tester.pump();

      expect(find.text('Errore nella rimozione'), findsOneWidget);
    });

    testWidgets('shows error snackbar when add/update fails', (tester) async {
      when(
        () => authRepository.currentUser,
      ).thenReturn(AppUser(id: 'u1', email: 'u1@mail.com'));
      when(
        () => addBookUseCase.call(any(), 'u1'),
      ).thenThrow(Exception('save failed'));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      await logic.handleStatusAction(context, buildBook(), 'read', 'toread');
      await tester.pump();

      expect(find.text('Impossibile aggiornare'), findsOneWidget);
    });
  });

  group('BookDetailLogic.handleAnalysis', () {
    testWidgets('returns null and shows snackbar when user is null', (
      tester,
    ) async {
      when(() => authRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      final result = await logic.handleAnalysis(context, buildBook());
      await tester.pump();

      expect(result, isNull);
      expect(find.text('Accedi per usare l\'AI'), findsOneWidget);
      verifyNever(() => addBookUseCase.call(any(), any()));
    });

    testWidgets('saves AI analysis using AddBookUseCase on success', (
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
      ).thenAnswer((_) async => 'analysis-ok');
      when(() => addBookUseCase.call(any(), 'u1')).thenAnswer((_) async {});

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      final result = await logic.handleAnalysis(context, buildBook());
      await tester.pump();

      expect(result, 'analysis-ok');
      final captured =
          verify(() => addBookUseCase.call(captureAny(), 'u1')).captured.first
              as Book;
      expect(captured.aiAnalysis, 'analysis-ok');
    });

    testWidgets('shows AI error snackbar when analysis throws', (tester) async {
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
      ).thenThrow(Exception('ai failed'));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final context = tester.element(find.byType(SizedBox));

      final result = await logic.handleAnalysis(context, buildBook());
      await tester.pump();

      expect(result, isNull);
      expect(find.text('Errore analisi AI'), findsOneWidget);
    });
  });
}
