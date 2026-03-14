import '../entities/book.dart';

abstract class BookRepository {
  // Metodi Database (Richiedono userId per la nuova struttura users/{id}/library)
  Stream<List<Book>> getUserBooksStream(String userId, String status);
  Future<void> addBook(Book book, String userId);
  Future<void> deleteBook(String userId, String bookId); // Aggiunto userId
  Future<void> updateBookStatus(
    String userId,
    String bookId,
    String newStatus,
  ); // Aggiunto userId
  Future<void> saveAnalysis(
    String userId,
    String bookId,
    String analysis,
  ); // Aggiunto userId

  // Metodi API
  Future<List<Book>> searchBooks(String query);
  Future<List<Book>> getBooksByCategory(String categoryId);
  Stream<Book?> getSingleBookStream(String userId, String bookId);
}
