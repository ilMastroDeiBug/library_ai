import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/book.dart';
import '../../services/utility_services/open_library_service.dart';

class SupabaseBookRepositoryImpl implements BookRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final OpenLibraryService _openLibService = OpenLibraryService();

  static const String _tableName = 'user_books';

  @override
  Stream<List<Book>> getUserBooksStream(String userId, String status) {
    return _supabase
        .from(_tableName)
        .stream(
          primaryKey: ['id'],
        ) // <-- FIX 1: La vera chiave primaria del database
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
            return Book.fromFirestore(
              mappedRow,
              row['book_id'],
            ); // Ricorda che era fromMap o fromFirestore
          }).toList();
        });
  }

  @override
  Stream<Book?> getSingleBookStream(String userId, String bookId) {
    String docId = bookId.replaceAll('/', '_');

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id']) // <-- FIX 1: La vera chiave primaria
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
      'status': book
          .status, // <-- FIX EXTRA: Deve prendere lo status corrente del libro, non forzare 'toread'
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      // <-- FIX 2: IL PEZZO CRUCIALE PER NON FARLO CRASHARE
      await _supabase
          .from(_tableName)
          .upsert(
            rowToInsert,
            onConflict:
                'user_id, book_id', // Specifichiamo la regola di conflitto!
          );
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
        .from(_tableName)
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
        .from(_tableName)
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
        .from(_tableName)
        .update({
          'ai_analysis': analysis,
          'timestamp': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('book_id', docId);
  }

  @override
  Future<List<Book>> searchBooks(String query) async {
    String normalized = query.replaceAll('_', ' ').trim();
    try {
      final res = await _openLibService.fetchBooks("subject:$normalized");
      if (res.isNotEmpty) return res;
    } catch (_) {}
    return await _openLibService.fetchBooks(normalized);
  }

  @override
  Future<List<Book>> getBooksByCategory(String categoryId) async {
    return await _openLibService.fetchBooks("subject:$categoryId");
  }
}
