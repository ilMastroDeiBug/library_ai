import '../entities/book.dart';

abstract class BookRepository {
  // Metodi Database (Richiedono userId per la nuova struttura users/{id}/library)
  Stream<List<Book>> getUserBooksStream(String userId, String status);
  Future<void> addBook(Book book, String userId);
  Future<void> deleteBook(String userId, String bookId);
  Future<void> updateBookStatus(String userId, String bookId, String newStatus);
  Future<void> saveAnalysis(String userId, String bookId, String analysis);

  // Metodi API
  Stream<Book?> getSingleBookStream(String userId, String bookId);

  // IL RADAR (Ricerca veloce in autocompletamento)
  Future<List<Book>> searchBooks(String query);

  // Esplorazione Categorie
  Future<List<Book>> getBooksByCategory(String categoryId);

  // IL CECCHINO (Merge OpenLibrary + Google Books + Supabase Cache)
  Future<Book> getBookDetails(Book partialBook);
}
