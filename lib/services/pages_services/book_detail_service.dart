import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/utility_services/ai_service.dart';

class BookDetailService {
  final AIService _aiService = AIService();

  /// Cambia lo stato da 'read' a 'toread' e viceversa su Firestore
  Future<String> toggleReadStatus({
    required String bookId,
    required String currentStatus,
    required Map<String, dynamic>
    bookData, // Passiamo i dati per salvarli se non esistono
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    final newStatus = currentStatus == 'read' ? 'toread' : 'read';

    // Aggiungiamo userId e timestamp ai dati da salvare
    final dataToSave = {
      ...bookData,
      'userId': user.uid,
      'status': newStatus,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .set(dataToSave, SetOptions(merge: true));

    return newStatus;
  }

  /// Esegue l'analisi AI e la salva nel documento del libro
  Future<String> analyzeAndSaveBook({
    required String bookId,
    required String title,
    required String author,
  }) async {
    // Profilo utente (In futuro potresti passarlo come parametro o leggerlo dal DB utente)
    const userProfile =
        "Sono un ragazzo di 16 anni, ambizioso, sviluppatore...";

    // 1. Chiamata AI
    final resultText = await _aiService.analyzeBook(
      title: title,
      author: author,
      userProfile: userProfile,
    );

    // 2. Salvataggio su Firestore
    await FirebaseFirestore.instance.collection('books').doc(bookId).set({
      'aiAnalysis': resultText,
    }, SetOptions(merge: true));

    return resultText;
  }

  // Test MVP connessione
  Future<String> runConnectionTest() async {
    return await _aiService.pingAI();
  }
}
