import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/entities/book.dart';
import '../../services/utility_services/open_library_service.dart';

class BookRepositoryImpl implements BookRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OpenLibraryService _openLibService = OpenLibraryService();

  // Helper per il percorso della libreria nidificata
  CollectionReference _libraryRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('library');

  @override
  Stream<List<Book>> getUserBooksStream(String userId, String status) {
    return _libraryRef(userId)
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Book.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // <-- FIX: AGGIUNTO IL METODO MANCANTE PER RISPETTARE L'INTERFACCIA
  @override
  Stream<Book?> getSingleBookStream(String userId, String bookId) {
    String docId = bookId.replaceAll('/', '_');
    return _libraryRef(userId).doc(docId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  @override
  Future<void> addBook(Book book, String userId) async {
    final data = book.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    String docId = book.id.replaceAll('/', '_');
    await _libraryRef(userId).doc(docId).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteBook(String userId, String bookId) async {
    String docId = bookId.replaceAll('/', '_');
    await _libraryRef(userId).doc(docId).delete();
  }

  @override
  Future<void> updateBookStatus(
    String userId,
    String bookId,
    String newStatus,
  ) async {
    String docId = bookId.replaceAll('/', '_');
    await _libraryRef(userId).doc(docId).update({'status': newStatus});
  }

  @override
  Future<void> saveAnalysis(
    String userId,
    String bookId,
    String analysis,
  ) async {
    String docId = bookId.replaceAll('/', '_');
    await _libraryRef(userId).doc(docId).set({
      'aiAnalysis': analysis,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
