import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/data/supabase_book_repository_impl.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/services/utility_services/google_books_service.dart';
import 'package:library_ai/services/utility_services/open_library_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoogleBooksService extends Mock implements GoogleBooksService {}

class MockOpenLibraryService extends Mock implements OpenLibraryService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockGoogleBooksService google;
  late SupabaseBookRepositoryImpl repository;

  final partialBook = Book(
    id: '/works/OL1W',
    title: 'Atomic Habits',
    author: 'James Clear',
    description: 'partial desc',
    thumbnailUrl: 'partial.jpg',
    pageCount: 0,
    rating: 3.0,
    ratingsCount: 12,
  );

  setUp(() {
    google = MockGoogleBooksService();
    repository = SupabaseBookRepositoryImpl(
      openLibraryService: MockOpenLibraryService(),
      googleBooksService: google,
      supabaseClient: MockSupabaseClient(),
    );
  });

  group('SupabaseBookRepositoryImpl.getBookDetails', () {
    test('cache hit returns cached book without sniper query', () async {
      repository = SupabaseBookRepositoryImpl(
        openLibraryService: MockOpenLibraryService(),
        googleBooksService: google,
        supabaseClient: MockSupabaseClient(),
        fetchCachedCatalogBook: (_) async => {
          'book_id': '_works_OL1W',
          'title': 'Atomic Habits',
          'author': 'James Clear',
          'description': 'cached',
          'cover_url': 'cached.jpg',
          'page_count': 300,
          'rating': 4.8,
          'ratings_count': 999,
        },
      );

      final result = await repository.getBookDetails(partialBook);

      expect(result.id, '_works_OL1W');
      expect(result.description, 'cached');
      verifyNever(() => google.searchBooks(any()));
    });

    test('cache miss + google result merges fields and persists', () async {
      Book? persisted;
      when(() => google.searchBooks(any())).thenAnswer(
        (_) async => [
          Book(
            id: 'g1',
            title: 'Atomic Habits',
            author: 'James Clear',
            description: 'google desc',
            thumbnailUrl: 'google.jpg',
            pageCount: 320,
            rating: 4.9,
            ratingsCount: 1200,
          ),
        ],
      );

      repository = SupabaseBookRepositoryImpl(
        openLibraryService: MockOpenLibraryService(),
        googleBooksService: google,
        supabaseClient: MockSupabaseClient(),
        fetchCachedCatalogBook: (_) async => null,
        persistCatalogBook: (book) async => persisted = book,
      );

      final result = await repository.getBookDetails(partialBook);

      expect(result.id, '_works_OL1W');
      expect(result.title, partialBook.title);
      expect(result.author, partialBook.author);
      expect(result.description, 'google desc');
      expect(result.thumbnailUrl, 'google.jpg');
      expect(result.pageCount, 320);
      expect(persisted, isNotNull);
      expect(persisted!.id, '_works_OL1W');
    });

    test('cache miss + no google result returns partialBook', () async {
      when(() => google.searchBooks(any())).thenAnswer((_) async => []);

      repository = SupabaseBookRepositoryImpl(
        openLibraryService: MockOpenLibraryService(),
        googleBooksService: google,
        supabaseClient: MockSupabaseClient(),
        fetchCachedCatalogBook: (_) async => null,
      );

      final result = await repository.getBookDetails(partialBook);

      expect(result.id, partialBook.id);
      expect(result.description, partialBook.description);
      expect(result.thumbnailUrl, partialBook.thumbnailUrl);
    });

    test('cache read/write errors do not block main result', () async {
      when(() => google.searchBooks(any())).thenAnswer(
        (_) async => [
          Book(
            id: 'g2',
            title: partialBook.title,
            author: partialBook.author,
            description: 'resilient desc',
            thumbnailUrl: 'resilient.jpg',
            pageCount: 250,
          ),
        ],
      );

      repository = SupabaseBookRepositoryImpl(
        openLibraryService: MockOpenLibraryService(),
        googleBooksService: google,
        supabaseClient: MockSupabaseClient(),
        fetchCachedCatalogBook: (_) async => throw Exception('read error'),
        persistCatalogBook: (_) async => throw Exception('write error'),
      );

      final result = await repository.getBookDetails(partialBook);

      expect(result.description, 'resilient desc');
      expect(result.thumbnailUrl, 'resilient.jpg');
    });
  });
}
