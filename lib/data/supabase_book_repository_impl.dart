import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/book.dart';
// FIX: Importa i tuoi nuovi service al posto di HardcoverService
import '../services/utility_services/open_library_service.dart';
import '../services/utility_services/google_books_service.dart';

class SupabaseBookRepositoryImpl implements BookRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // I nuovi Service passati tramite Dependency Injection
  final OpenLibraryService _openLibraryService;
  final GoogleBooksService _googleBooksService;

  static const String _userTableName = 'user_books';
  static const String _globalCatalogTable = 'books_catalog'; // Il tuo Scudo

  SupabaseBookRepositoryImpl({
    required OpenLibraryService openLibraryService,
    required GoogleBooksService googleBooksService,
  }) : _openLibraryService = openLibraryService,
       _googleBooksService = googleBooksService;

  // =========================================================================
  // METODI DB UTENTE (La Libreria Personale) - INVARIATI
  // =========================================================================

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
    String docId = bookId.replaceAll('/', '_');

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
    String docId = book.id.replaceAll('/', '_');

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

    try {
      await _supabase
          .from(_userTableName)
          .upsert(rowToInsert, onConflict: 'user_id, book_id');
      print("✅ LIBRO SALVATO CON SUCCESSO: ${book.title}");
    } catch (e) {
      print("❌ ERRORE SUPABASE: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteBook(String userId, String bookId) async {
    String docId = bookId.replaceAll('/', '_');
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
    String docId = bookId.replaceAll('/', '_');
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
    String docId = bookId.replaceAll('/', '_');
    await _supabase
        .from(_userTableName)
        .update({
          'ai_analysis': analysis,
          'timestamp': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('book_id', docId);
  }

  // =========================================================================
  // METODI API (L'Architettura Radar & Cecchino)
  // =========================================================================

  @override
  Future<List<Book>> searchBooks(String query) async {
    // IL RADAR: Usa SOLO OpenLibrary. Veloce, zero merge, perfetto per l'autocompletamento.
    String normalized = query.trim();
    if (normalized.isEmpty) return [];
    return await _openLibraryService.fetchBooks(normalized);
  }

  @override
  Future<List<Book>> getBooksByCategory(String categoryId) async {
    // ESPLORAZIONE: Sfruttiamo la potenza nativa di Google Books per i generi
    return await _googleBooksService.fetchBooksByCategory(categoryId);
  }

  @override
  Future<Book> getBookDetails(Book partialBook) async {
    // IL CECCHINO: Merge profondo e salvataggio in cache
    final String safeBookId = partialBook.id.replaceAll('/', '_');

    // 1. Controllo lo Scudo (Supabase Cache Globale)
    try {
      final cachedResponse = await _supabase
          .from(_globalCatalogTable)
          .select()
          .eq('book_id', safeBookId)
          .maybeSingle();

      if (cachedResponse != null) {
        print("⚡ CECCHINO: Libro '${partialBook.title}' trovato nel DB.");
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
    } catch (e) {
      print("Errore lettura DB Catalog: $e");
    }

    // 2. Se non c'è, scateno la ricerca mirata su Google Books
    print("🔍 CECCHINO: Cerco '${partialBook.title}' su Google Books...");
    final String sniperQuery =
        'intitle:"${partialBook.title}" inauthor:"${partialBook.author}"';
    final List<Book> googleResults = await _googleBooksService.searchBooks(
      sniperQuery,
    );

    Book finalMergedBook;

    if (googleResults.isNotEmpty) {
      final Book googleBook = googleResults.first;

      // IL MERGE
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
        // FIX: Aggiunto il fallback (?? 0) per la Null Safety
        pageCount: (googleBook.pageCount ?? 0) > 0
            ? googleBook.pageCount
            : partialBook.pageCount,
        rating: partialBook.rating,
        ratingsCount: partialBook.ratingsCount,
      );
    } else {
      finalMergedBook = partialBook;
    }

    // 3. Salvataggio Silenzioso su Supabase (Costruzione dell'Impero)
    try {
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
      print("🧱 IMPERO: Libro salvato in books_catalog!");
    } catch (e) {
      print("Errore durante il salvataggio in books_catalog: $e");
    }

    return finalMergedBook;
  }
}
