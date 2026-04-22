import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import '../../services/utility_services/ai_service.dart';

class BookDetailLogic {
  final AIService _aiService;

  BookDetailLogic({AIService? aiService})
    : _aiService = aiService ?? AIService();

  // Gestisce il click sui tasti (Aggiungi/Rimuovi/Sposta)
  Future<void> handleStatusAction(
    BuildContext context,
    Book liveBook,
    String targetStatus,
    String currentStatus,
  ) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted) _showMinimalSnackBar(context, "Devi essere loggato");
      return;
    }

    // RIMOZIONE
    if (currentStatus == targetStatus) {
      try {
        await sl<DeleteBookUseCase>().call(
          user.id,
          liveBook.id,
        ); // <-- FIX: cambiato da uid a id
        if (context.mounted) {
          _showMinimalSnackBar(context, "Rimosso dalla libreria");
        }
      } catch (e) {
        if (context.mounted) {
          _showMinimalSnackBar(context, "Errore nella rimozione");
        }
      }
      return;
    }

    // AGGIORNAMENTO
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
        status: targetStatus,
        aiAnalysis: liveBook.aiAnalysis,
      );

      await sl<AddBookUseCase>().call(
        bookToSave,
        user.id,
      ); // <-- FIX: cambiato da uid a id

      if (context.mounted) {
        _showMinimalSnackBar(
          context,
          targetStatus == 'read' ? "Segnato come letto" : "Aggiunto alla coda",
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showMinimalSnackBar(context, "Impossibile aggiornare");
      }
    }
  }

  // Gestisce l'analisi AI
  Future<String?> handleAnalysis(BuildContext context, Book liveBook) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (context.mounted) {
        _showMinimalSnackBar(context, "Accedi per usare l'AI");
      }
      return null;
    }

    try {
      final analysis = await _aiService.analyzeMedia(
        title: liveBook.title,
        type: 'book',
        userProfile: "16 anni, Architect, Developer, MMA",
        creator: liveBook.author,
      );

      final bookToSave = Book(
        id: liveBook.id,
        title: liveBook.title,
        author: liveBook.author,
        description: liveBook.description,
        thumbnailUrl: liveBook.thumbnailUrl,
        pageCount: liveBook.pageCount,
        rating: liveBook.rating,
        ratingsCount: liveBook.ratingsCount,
        status: liveBook.status,
        aiAnalysis: analysis,
      );

      await sl<AddBookUseCase>().call(
        bookToSave,
        user.id,
      ); // <-- FIX: cambiato da uid a id

      return analysis;
    } catch (e) {
      if (context.mounted) _showMinimalSnackBar(context, "Errore analisi AI");
      return null;
    }
  }

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
