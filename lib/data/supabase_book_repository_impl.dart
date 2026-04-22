import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/book.dart';
import '../services/utility_services/open_library_service.dart';
import '../services/utility_services/google_books_service.dart';

class SupabaseBookRepositoryImpl implements BookRepository {
  final SupabaseClient _supabase;

  final OpenLibraryService _openLibraryService;
  final GoogleBooksService _googleBooksService;

  final Future<Map<String, dynamic>?> Function(String safeBookId)?
  _fetchCachedCatalogBook;
  final Future<void> Function(Book book)? _persistCatalogBook;

  static const String _userTableName = 'user_books';
  static const String _globalCatalogTable = 'books_catalog';

  SupabaseBookRepositoryImpl({
    required OpenLibraryService openLibraryService,
    required GoogleBooksService googleBooksService,
    SupabaseClient? supabaseClient,
    Future<Map<String, dynamic>?> Function(String safeBookId)?
    fetchCachedCatalogBook,
    Future<void> Function(Book book)? persistCatalogBook,
  }) : _openLibraryService = openLibraryService,
       _googleBooksService = googleBooksService,
       _supabase = supabaseClient ?? Supabase.instance.client,
       _fetchCachedCatalogBook = fetchCachedCatalogBook,
       _persistCatalogBook = persistCatalogBook;

  @override
  Stream<List<Book>> getUserBooksStream(String userId, String status) {
    return _supabase
        .from(_userTableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .map((snapshot) {
          final filteredRows = snapshot
              .where((row) => row['status'] == status)
              .toList();

          return filteredRows.map((row) {
            final mappedRow = {
              'title': row['title'],
              'author': row['author'],
              'description': row['description'],
              'thumbnailUrl': row['thumbnail_url'],
              'pageCount': row['page_count'],
              'averageRating': row['rating'],
              'ratingsCount': row['ratings_count'],
              'status': row['status'],
              'aiAnalysis': row['ai_analysis'],
            };
            return Book.fromFirestore(mappedRow, row['book_id']);
          }).toList();
        });
  }

  @override
  Stream<Book?> getSingleBookStream(String userId, String bookId) {
    final docId = bookId.replaceAll('/', '_');

    return _supabase
        .from(_userTableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((snapshot) {
          final bookRows = snapshot
              .where((row) => row['book_id'] == docId)
              .toList();

          if (bookRows.isEmpty) return null;

          final row = bookRows.first;
          final mappedRow = {
            'title': row['title'],
            'author': row['author'],
            'description': row['description'],
            'thumbnailUrl': row['thumbnail_url'],
            'pageCount': row['page_count'],
            'averageRating': row['rating'],
            'ratingsCount': row['ratings_count'],
            'status': row['status'],
            'aiAnalysis': row['ai_analysis'],
          };
          return Book.fromFirestore(mappedRow, row['book_id']);
        });
  }

  @override
  Future<void> addBook(Book book, String userId) async {
    final docId = book.id.replaceAll('/', '_');

    final rowToInsert = {
      'user_id': userId,
      'book_id': docId,
      'title': book.title,
      'author': book.author,
      'description': book.description,
      'thumbnail_url': book.thumbnailUrl,
      'page_count': book.pageCount,
      'rating': book.rating,
      'ratings_count': book.ratingsCount,
      'status': book.status,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from(_userTableName)
        .upsert(rowToInsert, onConflict: 'user_id, book_id');
  }

  @override
  Future<void> deleteBook(String userId, String bookId) async {
    final docId = bookId.replaceAll('/', '_');
    await _supabase
        .from(_userTableName)
        .delete()
        .eq('user_id', userId)
        .eq('book_id', docId);
  }

  @override
  Future<void> updateBookStatus(
    String userId,
    String bookId,
    String newStatus,
  ) async {
    final docId = bookId.replaceAll('/', '_');
    await _supabase
        .from(_userTableName)
        .update({'status': newStatus})
        .eq('user_id', userId)
        .eq('book_id', docId);
  }

  @override
  Future<void> saveAnalysis(
    String userId,
    String bookId,
    String analysis,
  ) async {
    final docId = bookId.replaceAll('/', '_');
    await _supabase
        .from(_userTableName)
        .update({
          'ai_analysis': analysis,
          'timestamp': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('book_id', docId);
  }

  @override
  Future<List<Book>> searchBooks(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return [];
    return _openLibraryService.fetchBooks(normalized);
  }

  @override
  Future<List<Book>> getBooksByCategory(String categoryId) async {
    return _googleBooksService.fetchBooksByCategory(categoryId);
  }

  @override
  Future<Book> getBookDetails(Book partialBook) async {
    final safeBookId = partialBook.id.replaceAll('/', '_');

    try {
      final cachedResponse =
          await _fetchCachedCatalogBook?.call(safeBookId) ??
          await _supabase
              .from(_globalCatalogTable)
              .select()
              .eq('book_id', safeBookId)
              .maybeSingle();

      if (cachedResponse != null) {
        return Book(
          id: cachedResponse['book_id'],
          title: cachedResponse['title'],
          author: cachedResponse['author'],
          description: cachedResponse['description'],
          thumbnailUrl: cachedResponse['cover_url'],
          pageCount: cachedResponse['page_count'] ?? partialBook.pageCount,
          rating:
              (cachedResponse['rating'] as num?)?.toDouble() ??
              partialBook.rating,
          ratingsCount:
              cachedResponse['ratings_count'] ?? partialBook.ratingsCount,
        );
      }
    } catch (_) {
      // non blocca il flusso principale
    }

    final sniperQuery =
        'intitle:"${partialBook.title}" inauthor:"${partialBook.author}"';
    final googleResults = await _googleBooksService.searchBooks(sniperQuery);

    Book finalMergedBook;
    if (googleResults.isNotEmpty) {
      final googleBook = googleResults.first;
      finalMergedBook = Book(
        id: safeBookId,
        title: partialBook.title,
        author: partialBook.author,
        description: googleBook.description.isNotEmpty
            ? googleBook.description
            : partialBook.description,
        thumbnailUrl: googleBook.thumbnailUrl.isNotEmpty
            ? googleBook.thumbnailUrl
            : partialBook.thumbnailUrl,
        pageCount: (googleBook.pageCount ?? 0) > 0
            ? googleBook.pageCount
            : partialBook.pageCount,
        rating: partialBook.rating,
        ratingsCount: partialBook.ratingsCount,
      );
    } else {
      finalMergedBook = partialBook;
    }

    try {
      if (_persistCatalogBook != null) {
        await _persistCatalogBook!(finalMergedBook);
      } else {
        await _supabase.from(_globalCatalogTable).upsert({
          'book_id': finalMergedBook.id,
          'title': finalMergedBook.title,
          'author': finalMergedBook.author,
          'description': finalMergedBook.description,
          'cover_url': finalMergedBook.thumbnailUrl,
          'page_count': finalMergedBook.pageCount,
          'rating': finalMergedBook.rating,
          'ratings_count': finalMergedBook.ratingsCount,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // non blocca il flusso principale
    }

    return finalMergedBook;
  }
}
