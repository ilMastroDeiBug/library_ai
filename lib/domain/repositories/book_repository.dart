import '../entities/book.dart'; // O models/book_widgets/book_model.dart

abstract class BookRepository {
  // DB
  Stream<List<Book>> getUserBooksStream(String userId, String status);
  Future<void> addBook(Book book, String userId);
  Future<void> deleteBook(String bookId);
  Future<void> updateBookStatus(String bookId, String newStatus);
  Future<void> saveAnalysis(String bookId, String analysis);

  // API
  Future<List<Book>> searchBooks(String query); // Via OpenLibrary
  Future<List<Book>> getBooksByCategory(String categoryId); // Via GoogleBooks
}
