import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/book.dart';
// IMPORTIAMO SOLO OPEN LIBRARY
import '../../services/utility_services/open_library_service.dart';

class BookRepositoryImpl implements BookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // UNICA FONTE DI VERITÀ API
  final OpenLibraryService _openLibService = OpenLibraryService();

  // --- PARTE DATABASE (Firebase) ---

  @override
  Stream<List<Book>> getUserBooksStream(String userId, String status) {
    return _firestore
        .collection('books')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Book.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> addBook(Book book, String userId) async {
    final data = book.toMap();
    data['userId'] = userId;
    data['timestamp'] = FieldValue.serverTimestamp();

    // Se l'ID è un ID di OpenLibrary (spesso contengono path), lo usiamo come ID documento
    if (book.id.isNotEmpty && !book.id.startsWith('manual_')) {
      await _firestore.collection('books').doc(book.id).set(data);
    } else {
      await _firestore.collection('books').add(data);
    }
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).delete();
  }

  @override
  Future<void> updateBookStatus(String bookId, String newStatus) async {
    await _firestore.collection('books').doc(bookId).update({
      'status': newStatus,
    });
  }

  @override
  Future<void> saveAnalysis(String bookId, String analysis) async {
    await _firestore.collection('books').doc(bookId).update({
      'aiAnalysis': analysis,
    });
  }

  // --- PARTE API (Open Library 100%) ---

  @override
  Future<List<Book>> searchBooks(String query) async {
    // Normalizziamo query provenienti dall'UI (es. 'science_fiction' -> 'science fiction')
    String normalized = query.replaceAll('_', ' ').trim();

    // Se l'utente/servizio ha passato un identificatore di categoria esplicito,
    // manteniamo la chiamata generica. Altrimenti proviamo prima come subject
    // (più rilevante per categorie) e poi come ricerca libera.
    try {
      // Proviamo come subject (migliora i risultati per categorie)
      final subjectResults = await _openLibService.fetchBooks(
        "subject:$normalized",
      );
      if (subjectResults.isNotEmpty) return subjectResults;
    } catch (e) {
      // Ignora e prova la ricerca generica
      print('Subject search failed: $e');
    }

    // Fallback: ricerca libera con termine normalizzato
    return await _openLibService.fetchBooks(normalized);
  }

  @override
  Future<List<Book>> getBooksByCategory(String categoryId) async {
    // TRUCCO ARCHITECT:
    // Open Library cerca per soggetto usando "subject:nome_categoria".
    // Passiamo questo al nostro service che già gestisce le query.
    return await _openLibService.fetchBooks("subject:$categoryId");
  }
}
