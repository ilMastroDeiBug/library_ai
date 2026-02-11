import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserBooksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream dei libri dell'utente per una certa status (read/toread)
  Stream<QuerySnapshot> getUserBooksStream(String status) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('books')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .limit(10) // Limitiamo a 10 per la home
        .snapshots();
  }

  // Aggiunta manuale di un libro
  Future<void> addBookManually({
    required String title,
    required String author,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    await _firestore.collection('books').add({
      'title': title,
      'author': author,
      'userId': user.uid,
      'status': 'toread',
      'category': 'Generico',
      'thumbnailUrl': '', // Nessuna immagine per i manuali
      'description': 'Aggiunto manualmente',
      'timestamp': FieldValue.serverTimestamp(),
      // Aggiungiamo campi vuoti per evitare null check fastidiosi
      'pageCount': 0,
      'averageRating': 0.0,
      'ratingsCount': 0,
    });
  }
}
