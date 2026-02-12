import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/book_widgets/book_model.dart';
import '../services/pages_services/book_detail_service.dart';
import '/models/book_widgets/book_stats_bar.dart';
import '../models/ai_analysis_section.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final BookDetailService _service = BookDetailService();
  bool _isAnalyzing = false;

  // COLORE TEMA UNIFICATO
  static const Color _brandColor = Colors.orangeAccent;

  Future<void> _handleStatusToggle(Book liveBook, String currentStatus) async {
    try {
      final newStatus = await _service.toggleReadStatus(
        bookId: liveBook.id,
        currentStatus: currentStatus,
        bookData: liveBook.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'read'
                  ? "Salvato in libreria."
                  : "Spostato in 'Da Leggere'.",
            ),
            // Feedback colore: Verde per successo, Arancio per pending
            backgroundColor: newStatus == 'read' ? Colors.green : _brandColor,
          ),
        );
      }
    } catch (e) {
      print("Errore: $e");
    }
  }

  Future<void> _handleAnalysis(Book liveBook) async {
    setState(() => _isAnalyzing = true);
    try {
      await _service.analyzeAndSaveBook(
        bookId: liveBook.id,
        title: liveBook.title,
        author: liveBook.author,
      );
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
          currentStatus = data['status'] ?? 'toread';
          storedAnalysis = data['aiAnalysis'];
        }
        final isRead = currentStatus == 'read';

        return Scaffold(
          backgroundColor: const Color(0xFF121212), // Sfondo nero profondo
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
            // Rimosso il container con gradiente per pulizia, usiamo sfondo scaffold
            child: Column(
              children: [
                // 1. HEADER COPERTINA SFUMATA (Effetto Cinema anche per libri)
                SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      // Immagine Sfondo sfuocata
                      Positioned.fill(
                        child: Image.network(
                          liveBook.thumbnailUrl,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.6),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                      // Gradiente per coprire il taglio in basso
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
                      // Copertina in primo piano
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. CONTENUTO SCORREVOLE
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
                        style: TextStyle(
                          fontSize: 14,
                          color: _brandColor, // Autore in giallo/arancio
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // STATS BAR
                      BookStatsBar(
                        book: liveBook,
                      ), // Assicurati che questo widget si adatti ai colori o sia neutro
                      const SizedBox(height: 30),

                      // STATUS BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRead
                                ? const Color(
                                    0xFF1B5E20,
                                  ) // Verde scuro per completato
                                : _brandColor, // Giallo per azione
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

                      // AI SECTION
                      AIAnalysisSection(
                        analysisText: storedAnalysis,
                        isAnalyzing: _isAnalyzing,
                        onAnalyzeTap: () => _handleAnalysis(liveBook),
                      ),

                      const SizedBox(height: 40),

                      // SINOSSI
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
                            : "Nessuna descrizione disponibile per questo titolo.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6, // Migliore leggibilità
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
