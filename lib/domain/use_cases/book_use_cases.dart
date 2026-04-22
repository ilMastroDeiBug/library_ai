import 'package:library_ai/domain/repositories/book_repository.dart';
import 'package:library_ai/domain/entities/book.dart';

// --- DB USE CASES ---

class GetUserBooksUseCase {
  final BookRepository repository;
  GetUserBooksUseCase(this.repository);

  Stream<List<Book>> call(String userId, String status) =>
      repository.getUserBooksStream(userId, status);
}

class AddBookUseCase {
  final BookRepository repository;
  AddBookUseCase(this.repository);

  Future<void> call(Book book, String userId) =>
      repository.addBook(book, userId);
}

class DeleteBookUseCase {
  final BookRepository repository;
  DeleteBookUseCase(this.repository);

  Future<void> call(String userId, String bookId) =>
      repository.deleteBook(userId, bookId);
}

class ToggleBookStatusUseCase {
  final BookRepository repository;
  ToggleBookStatusUseCase(this.repository);

  Future<String> call(
    String userId,
    String bookId,
    String currentStatus,
  ) async {
    final newStatus = currentStatus == 'read' ? 'toread' : 'read';
    await repository.updateBookStatus(userId, bookId, newStatus);
    return newStatus;
  }
}

class GetSingleBookUseCase {
  final BookRepository repository;
  GetSingleBookUseCase(this.repository);

  Stream<Book?> call(String userId, String bookId) {
    return repository.getSingleBookStream(userId, bookId);
  }
}

class SaveBookAnalysisUseCase {
  final BookRepository repository;
  SaveBookAnalysisUseCase(this.repository);

  Future<void> call(String userId, String bookId, String analysis) =>
      repository.saveAnalysis(userId, bookId, analysis);
}

// --- API USE CASES ---

class SearchBooksUseCase {
  final BookRepository repository;
  SearchBooksUseCase(this.repository);

  Future<List<Book>> call(String query) => repository.searchBooks(query);
}

class GetBooksByCategoryUseCase {
  final BookRepository repository;
  GetBooksByCategoryUseCase(this.repository);

  Future<List<Book>> call(String categoryId) =>
      repository.getBooksByCategory(categoryId);
}

// NUOVO: IL CECCHINO (Merge Dati)
class GetFullBookDetailsUseCase {
  final BookRepository repository;
  GetFullBookDetailsUseCase(this.repository);

  Future<Book> call(Book partialBook) => repository.getBookDetails(partialBook);
}
