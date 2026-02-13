import 'package:library_ai/domain/repositories/book_repository.dart';
import 'package:library_ai/domain/entities/book.dart';

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
  Future<void> call(String bookId) => repository.deleteBook(bookId);
}

class ToggleBookStatusUseCase {
  final BookRepository repository;
  ToggleBookStatusUseCase(this.repository);
  Future<String> call(String bookId, String currentStatus) async {
    final newStatus = currentStatus == 'read' ? 'toread' : 'read';
    await repository.updateBookStatus(bookId, newStatus);
    return newStatus;
  }
}

class SaveBookAnalysisUseCase {
  final BookRepository repository;
  SaveBookAnalysisUseCase(this.repository);
  Future<void> call(String bookId, String analysis) =>
      repository.saveAnalysis(bookId, analysis);
}

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
