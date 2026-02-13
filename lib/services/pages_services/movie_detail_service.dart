import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/utility_services/ai_service.dart'; // Assumiamo che esista già
import 'package:library_ai/domain/entities/movie.dart'; // Assumiamo che esista già

class MovieDetailService {
  final AIService _aiService = AIService();

  /// Cambia stato: 'watched' <-> 'towatch'
  Future<String> toggleWatchStatus({
    required Movie movie,
    required String currentStatus,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Utente non loggato");

    // Logica toggle: se è 'watched' diventa 'towatch', e viceversa.
    // Default se non esiste: 'towatch'
    final newStatus = currentStatus == 'watched' ? 'towatch' : 'watched';

    // Dati da salvare
    final dataToSave = {
      'id': movie.id, // ID Numerico TMDB
      'title': movie.title,
      'overview': movie.overview,
      'posterPath': movie.posterPath,
      'backdropPath': movie.backdropPath,
      'voteAverage': movie.voteAverage,
      'releaseDate': movie.releaseDate,

      // Campi di sistema
      'userId': user.uid,
      'status': newStatus,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Usiamo l'ID TMDB come ID documento, ma convertito in stringa
    // Esempio: movies/12345
    await FirebaseFirestore.instance
        .collection('movies')
        .doc(movie.id.toString())
        .set(dataToSave, SetOptions(merge: true));

    return newStatus;
  }

  /// Analisi AI del Film
  Future<String> analyzeAndSaveMovie({
    required int movieId,
    required String title,
  }) async {
    // Profilo utente statico per ora
    const userProfile =
        "Sono un ragazzo di 16 anni, ambizioso, sviluppatore...";

    // 1. Chiamata AI (Nota: dovrai aggiungere un metodo analyzeMovie in AIService
    // oppure usare analyzeBook adattando il prompt, ma meglio uno dedicato)
    final resultText = await _aiService.analyzeMedia(
      title: title,
      type: 'movie', // Parametro per dire all'AI che è un film
      userProfile: userProfile,
    );

    // 2. Salvataggio su Firestore
    await FirebaseFirestore.instance
        .collection('movies')
        .doc(movieId.toString())
        .set({'aiAnalysis': resultText}, SetOptions(merge: true));

    return resultText;
  }
}
