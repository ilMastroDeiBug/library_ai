/*import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/book.dart';
import '../services/utility_services/open_library_service.dart';
import '../services/utility_services/google_books_service.dart';
import '../services/utility_services/cinelib_cache_service.dart';

class SupabaseBookRepositoryImpl implements BookRepository {
  final SupabaseClient _supabase;

  final OpenLibraryService _openLibraryService;
  final GoogleBooksService _googleBooksService;
  final CinelibCacheService _cacheService;

  final Future<Map<String, dynamic>?> Function(String safeBookId)?
  _fetchCachedCatalogBook;
  final Future<void> Function(Book book)? _persistCatalogBook;

  static const String _userTableName = 'user_books';
  static const String _globalCatalogTable = 'books_catalog';

  SupabaseBookRepositoryImpl({
    required OpenLibraryService openLibraryService,
    required GoogleBooksService googleBooksService,
    SupabaseClient? supabaseClient,
    CinelibCacheService? cacheService,
    Future<Map<String, dynamic>?> Function(String safeBookId)?
    fetchCachedCatalogBook,
    Future<void> Function(Book book)? persistCatalogBook,
  }) : _openLibraryService = openLibraryService,
       _googleBooksService = googleBooksService,
       _supabase = supabaseClient ?? Supabase.instance.client,
       _cacheService = cacheService ?? CinelibCacheService(),
       _fetchCachedCatalogBook = fetchCachedCatalogBook,
       _persistCatalogBook = persistCatalogBook;

  @override
  Stream<List<Book>> getUserBooksStream(String userId, String status) async* {
    final cacheKey = 'books_${userId}_$status';
    final cacheBox = Hive.box('cinelib_cache');

    final cachedRows = _readCachedRows(cacheBox, cacheKey);
    if (cachedRows != null) {
      yield _mapBookRowsToEntities(cachedRows, status);
    }

    try {
      final snapshot = await _supabase
          .from(_userTableName)
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      final rows = snapshot
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final filteredRows = rows
          .where((row) => row['status'] == status)
          .toList();

      await cacheBox.put(cacheKey, filteredRows);
      for (final row in filteredRows) {
        final bookId = row['book_id'];
        if (bookId != null) {
          await cacheBox.put('book_${userId}_$bookId', row);
        }
      }

      yield _mapBookRowsToEntities(filteredRows, status);
    } catch (_) {
      // Offline o errore: la UI continua a usare l'ultimo yield cache.
    }
  }

  @override
  Stream<Book?> getSingleBookStream(String userId, String bookId) async* {
    final docId = bookId.replaceAll('/', '_');
    final cacheKey = 'book_${userId}_$docId';
    final cacheBox = Hive.box('cinelib_cache');

    final cachedRow = _readCachedRow(cacheBox, cacheKey);
    if (cachedRow != null) {
      yield _mapBookRowToEntity(cachedRow);
    }

    try {
      final snapshot = await _supabase
          .from(_userTableName)
          .select()
          .eq('user_id', userId)
          .eq('book_id', docId);

      if (snapshot.isEmpty) {
        await _cacheService.deleteBook(userId: userId, bookId: docId);
        yield null;
        return;
      }

      final row = Map<String, dynamic>.from(snapshot.first);
      await _cacheService.upsertBook(
        userId: userId,
        bookId: docId,
        row: row,
      );

      yield _mapBookRowToEntity(row);
    } catch (_) {
      // Offline o errore: la UI continua a usare l'ultimo yield cache.
    }
  }

  List<Map<String, dynamic>>? _readCachedRows(Box cacheBox, String cacheKey) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! List) return null;

    return cached
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Map<String, dynamic>? _readCachedRow(Box cacheBox, String cacheKey) {
    final cached = cacheBox.get(cacheKey);
    if (cached is! Map) return null;

    return Map<String, dynamic>.from(cached);
  }

  List<Book> _mapBookRowsToEntities(
    List<Map<String, dynamic>> rows,
    String status,
  ) {
    return rows
        .where((row) => row['status'] == status)
        .map(_mapBookRowToEntity)
        .toList();
  }

  Book _mapBookRowToEntity(Map<String, dynamic> row) {
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

    // Optimistic Update
    await _cacheService.upsertBook(
      userId: userId,
      bookId: docId,
      row: rowToInsert,
    );

    try {
      await _supabase
          .from(_userTableName)
          .upsert(rowToInsert, onConflict: 'user_id, book_id');
    } catch (_) {}
  }

  @override
  Future<void> deleteBook(String userId, String bookId) async {
    final docId = bookId.replaceAll('/', '_');
    // Optimistic Update
    await _cacheService.deleteBook(userId: userId, bookId: docId);

    try {
      await _supabase
          .from(_userTableName)
          .delete()
          .eq('user_id', userId)
          .eq('book_id', docId);
    } catch (_) {}
  }

  @override
  Future<void> updateBookStatus(
    String userId,
    String bookId,
    String newStatus,
  ) async {
    final docId = bookId.replaceAll('/', '_');
    final timestamp = DateTime.now().toIso8601String();
    // Optimistic Update
    await _cacheService.updateBookStatus(
      userId: userId,
      bookId: docId,
      newStatus: newStatus,
      timestamp: timestamp,
    );

    try {
      await _supabase
          .from(_userTableName)
          .update({'status': newStatus, 'timestamp': timestamp})
          .eq('user_id', userId)
          .eq('book_id', docId);
    } catch (_) {}
  }

  @override
  Future<void> saveAnalysis(
    String userId,
    String bookId,
    String analysis,
  ) async {
    final docId = bookId.replaceAll('/', '_');
    final timestamp = DateTime.now().toIso8601String();

    // Optimistic Update
    final cacheBox = Hive.box('cinelib_cache');
    final cachedRow = _readCachedRow(cacheBox, 'book_${userId}_$docId');
    if (cachedRow != null) {
      cachedRow['ai_analysis'] = analysis;
      cachedRow['timestamp'] = timestamp;
      await _cacheService.upsertBook(
        userId: userId,
        bookId: docId,
        row: cachedRow,
      );
    }

    try {
      await _supabase
          .from(_userTableName)
          .update({'ai_analysis': analysis, 'timestamp': timestamp})
          .eq('user_id', userId)
          .eq('book_id', docId);
    } catch (_) {}
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
    final cacheBox = Hive.box('cinelib_cache');
    final catalogCacheKey = 'catalog_book_$safeBookId';
    final cachedCatalogBook = cacheBox.get(catalogCacheKey);

    if (cachedCatalogBook is Map) {
      return _mapCatalogRowToBook(
        Map<String, dynamic>.from(cachedCatalogBook),
        partialBook,
      );
    }

    try {
      final cachedResponse =
          await _fetchCachedCatalogBook?.call(safeBookId) ??
          await _supabase
              .from(_globalCatalogTable)
              .select()
              .eq('book_id', safeBookId)
              .maybeSingle();

      if (cachedResponse != null) {
        final catalogRow = Map<String, dynamic>.from(cachedResponse);
        await cacheBox.put(catalogCacheKey, catalogRow);
        return _mapCatalogRowToBook(catalogRow, partialBook);
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
      final catalogRow = {
        'book_id': finalMergedBook.id,
        'title': finalMergedBook.title,
        'author': finalMergedBook.author,
        'description': finalMergedBook.description,
        'cover_url': finalMergedBook.thumbnailUrl,
        'page_count': finalMergedBook.pageCount,
        'rating': finalMergedBook.rating,
        'ratings_count': finalMergedBook.ratingsCount,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_persistCatalogBook != null) {
        await _persistCatalogBook(finalMergedBook);
      } else {
        await _supabase.from(_globalCatalogTable).upsert(catalogRow);
      }
      await cacheBox.put(catalogCacheKey, catalogRow);
    } catch (_) {
      // non blocca il flusso principale
    }

    return finalMergedBook;
  }

  Book _mapCatalogRowToBook(
    Map<String, dynamic> cachedResponse,
    Book partialBook,
  ) {
    return Book(
      id: cachedResponse['book_id'],
      title: cachedResponse['title'],
      author: cachedResponse['author'],
      description: cachedResponse['description'],
      thumbnailUrl: cachedResponse['cover_url'],
      pageCount: cachedResponse['page_count'] ?? partialBook.pageCount,
      rating:
          (cachedResponse['rating'] as num?)?.toDouble() ?? partialBook.rating,
      ratingsCount: cachedResponse['ratings_count'] ?? partialBook.ratingsCount,
    );
  }
}
*/
