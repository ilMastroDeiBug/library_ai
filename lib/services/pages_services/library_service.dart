import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream dei libri dell'utente per uno specifico status
  Stream<QuerySnapshot> getUserBooksStream(String status) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('books')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Stream per il conteggio dei libri (per le statistiche)
  Stream<int> getBookCountStream(String status) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('books')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Eliminazione di un libro
  Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
    } catch (e) {
      throw Exception("Errore durante l'eliminazione: $e");
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
