import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import '../../domain/entities/book.dart';
import '../../services/utility_services/ai_service.dart';
import '/models/book_widgets/book_stats_bar.dart';
import '../models/ai_analysis_section.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isAnalyzing = false;
  static const Color _brandColor = Colors.orangeAccent;

  Future<void> _handleStatusToggle(Book liveBook, String currentStatus) async {
    try {
      final newStatus = await sl<ToggleBookStatusUseCase>().call(
        liveBook.id,
        currentStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'read'
                  ? "Salvato in libreria."
                  : "Spostato in 'Da Leggere'.",
            ),
            backgroundColor: newStatus == 'read' ? Colors.green : _brandColor,
          ),
        );
      }
    } catch (e) {
      // Fallback per libri non ancora nel DB
      try {
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
            status: currentStatus == 'read' ? 'toread' : 'read',
          );
          await sl<AddBookUseCase>().call(bookToSave, userStream.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Libro aggiunto al Database."),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (innerE) {
        print("Errore critico salvataggio: $innerE");
      }
    }
  }

  Future<void> _handleAnalysis(Book liveBook) async {
    setState(() => _isAnalyzing = true);
    try {
      final aiService = AIService();

      final analysis = await aiService.analyzeMedia(
        title: liveBook.title,
        type: 'book',
        userProfile: "16 anni, Developer, MMA",
        creator: liveBook.author,
      );

      // Salva l'analisi nel DB usando lo Use Case
      await sl<SaveBookAnalysisUseCase>().call(liveBook.id, analysis);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Errore analisi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .doc(widget.book.id)
          .snapshots(),
      builder: (context, snapshot) {
        Book liveBook = widget.book;
        String currentStatus = 'toread';
        String? storedAnalysis;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          liveBook = Book.fromFirestore(data, widget.book.id);
          currentStatus = liveBook.status;
          storedAnalysis = liveBook.aiAnalysis;
        }
        final isRead = currentStatus == 'read';

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          liveBook.thumbnailUrl,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.6),
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey[900]),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xFF121212)],
                              stops: [0.3, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Hero(
                          tag: liveBook.id,
                          child: Container(
                            height: 240,
                            width: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: _brandColor.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                              image: DecorationImage(
                                image: NetworkImage(liveBook.thumbnailUrl),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        liveBook.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        liveBook.author.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _brandColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 30),
                      BookStatsBar(book: liveBook),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRead
                                ? const Color(0xFF1B5E20)
                                : _brandColor,
                            foregroundColor: isRead
                                ? Colors.white
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: _brandColor.withOpacity(0.3),
                          ),
                          onPressed: () =>
                              _handleStatusToggle(liveBook, currentStatus),
                          icon: Icon(
                            isRead ? Icons.undo : Icons.check_circle_outline,
                          ),
                          label: Text(
                            isRead ? "COMPLETATO" : "SEGNA COME LETTO",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      AIAnalysisSection(
                        analysisText: storedAnalysis,
                        isAnalyzing: _isAnalyzing,
                        onAnalyzeTap: () => _handleAnalysis(liveBook),
                      ),
                      const SizedBox(height: 40),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "SINOSSI",
                          style: TextStyle(
                            color: Colors.white30,
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        liveBook.description.isNotEmpty
                            ? liveBook.description
                            : "Nessuna descrizione disponibile.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
