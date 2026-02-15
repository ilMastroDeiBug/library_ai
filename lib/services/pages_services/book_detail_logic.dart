import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import '../../services/utility_services/ai_service.dart';

class BookDetailLogic {
  // Gestisce il click sui tasti (Aggiungi/Rimuovi/Sposta)
  Future<void> handleStatusAction(
    BuildContext context,
    Book liveBook,
    String targetStatus,
    String currentStatus,
  ) async {
    // 1. Recupero Utente
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted) _showMinimalSnackBar(context, "Devi essere loggato");
      return;
    }

    // 2. RIMOZIONE: Se clicco sullo stato già attivo, elimino il libro dalla libreria dell'utente
    if (currentStatus == targetStatus) {
      try {
        // CORRETTO: Passiamo userId e bookId
        await sl<DeleteBookUseCase>().call(user.uid, liveBook.id);
        if (context.mounted)
          _showMinimalSnackBar(context, "Rimosso dalla libreria");
      } catch (e) {
        if (context.mounted)
          _showMinimalSnackBar(context, "Errore nella rimozione");
      }
      return;
    }

    // 3. AGGIORNAMENTO/AGGIUNTA
    try {
      final bookToSave = Book(
        id: liveBook.id,
        title: liveBook.title,
        author: liveBook.author,
        description: liveBook.description,
        thumbnailUrl: liveBook.thumbnailUrl,
        pageCount: liveBook.pageCount,
        rating: liveBook.rating,
        ratingsCount: liveBook.ratingsCount,
        status: targetStatus, // Nuovo stato (read o toread)
        aiAnalysis: liveBook.aiAnalysis,
      );

      // CORRETTO: Salvataggio nel path users/{userId}/library/{bookId}
      await sl<AddBookUseCase>().call(bookToSave, user.uid);

      if (context.mounted) {
        _showMinimalSnackBar(
          context,
          targetStatus == 'read'
              ? "Segnato come letto"
              : "Aggiunto alla coda di lettura",
        );
      }
    } catch (e) {
      if (context.mounted)
        _showMinimalSnackBar(context, "Impossibile aggiornare");
    }
  }

  // Gestisce l'analisi AI
  Future<String?> handleAnalysis(BuildContext context, Book liveBook) async {
    // 1. Recupero Utente
    final user = sl<AuthRepository>().currentUser;
    if (user == null) return null;

    try {
      final aiService = AIService();
      final analysis = await aiService.analyzeMedia(
        title: liveBook.title,
        type: 'book',
        userProfile: "16 anni, Architect, Developer, MMA", // Profilo Architect
        creator: liveBook.author,
      );

      // 2. Salva nel DB associandolo all'utente corrente
      // CORRETTO: Passiamo userId, bookId e l'analisi
      await sl<SaveBookAnalysisUseCase>().call(user.uid, liveBook.id, analysis);

      return analysis;
    } catch (e) {
      if (context.mounted) _showMinimalSnackBar(context, "Errore analisi AI");
      return null;
    }
  }

  // Helper Grafico per i messaggi
  void _showMinimalSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
