import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/utility_services/ai_service.dart'; // Assicurati che il path sia corretto

class BookDetailService {
  final AIService _aiService = AIService();

  /// Cambia lo stato da 'read' a 'toread' e viceversa su Firestore
  Future<String> toggleReadStatus({
    required String bookId,
    required String currentStatus,
    required Map<String, dynamic> bookData,
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

    // Usiamo l'ID del libro (che abbiamo sanitizzato nel service di ricerca)
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
    // Profilo utente (In futuro lo leggeremo dalle impostazioni)
    const userProfile =
        "Sono un ragazzo di 16 anni, ambizioso, sviluppatore Full Stack e praticante di MMA.";

    // 1. Chiamata AI (AGGIORNATA)
    // Usiamo analyzeMedia specificando che è un libro
    final resultText = await _aiService.analyzeMedia(
      title: title,
      type: 'book', // <--- Parametro cruciale
      userProfile: userProfile,
      creator: author, // Passiamo l'autore
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
