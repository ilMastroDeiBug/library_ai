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
    // 1. RIMOZIONE: Se clicco sullo stato già attivo
    if (currentStatus == targetStatus) {
      try {
        await sl<DeleteBookUseCase>().call(liveBook.id);
        if (context.mounted)
          _showMinimalSnackBar(context, "Rimosso dalla libreria");
      } catch (e) {
        if (context.mounted)
          _showMinimalSnackBar(context, "Errore nella rimozione");
      }
      return;
    }

    // 2. AGGIORNAMENTO/AGGIUNTA
    try {
      // Usiamo AddBookUseCase per fare un "Upsert" (Inserisci o Aggiorna) sicuro
      final authRepo = sl<AuthRepository>();
      final userStream = await authRepo.userStream.first;

      if (userStream != null) {
        final bookToSave = Book(
          id: liveBook.id,
          title: liveBook.title,
          author: liveBook.author,
          description: liveBook.description,
          thumbnailUrl: liveBook.thumbnailUrl,
          pageCount: liveBook.pageCount,
          rating: liveBook.rating,
          ratingsCount: liveBook.ratingsCount,
          status: targetStatus, // Forziamo il nuovo stato
          aiAnalysis: liveBook.aiAnalysis,
        );
        await sl<AddBookUseCase>().call(bookToSave, userStream.id);
      }

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
    try {
      final aiService = AIService();
      final analysis = await aiService.analyzeMedia(
        title: liveBook.title,
        type: 'book',
        userProfile: "16 anni, Developer, MMA", // Profilo utente
        creator: liveBook.author,
      );

      // Salva nel DB
      await sl<SaveBookAnalysisUseCase>().call(liveBook.id, analysis);
      return analysis;
    } catch (e) {
      if (context.mounted) _showMinimalSnackBar(context, "Errore analisi AI");
      return null;
    }
  }

  // Helper Grafico per i messaggi (Grigio scuro, no emoji)
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
        backgroundColor: const Color(0xFF333333), // Grigio Scuro elegante
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
