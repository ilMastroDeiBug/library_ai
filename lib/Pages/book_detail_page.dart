import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../services/pages_services/book_detail_service.dart';
// IMPORTA I NUOVI WIDGET
import '../models/book_stats_bar.dart';
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

  // --- FUNZIONI PONTE UI-SERVICE ---

  Future<void> _handleStatusToggle(Book liveBook, String currentStatus) async {
    try {
      final newStatus = await _service.toggleReadStatus(
        bookId: liveBook.id,
        currentStatus: currentStatus,
        bookData: liveBook.toMap(), // Assumendo che Book abbia toMap()
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'read'
                  ? "Salvato in libreria."
                  : "Spostato in 'Da Leggere'.",
            ),
            backgroundColor: newStatus == 'read'
                ? Colors.green
                : Colors.orangeAccent,
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
        // Logica di merge dati (Live + Statici)
        Book liveBook = widget.book;
        String currentStatus = 'toread';
        String? storedAnalysis;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          currentStatus = data['status'] ?? 'toread';
          storedAnalysis = data['aiAnalysis'];
          // Qui potresti aggiornare liveBook con i dati freschi se necessario
        }
        final isRead = currentStatus == 'read';

        return Scaffold(
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
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C2C2C), Color(0xFF121212)],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              child: Column(
                children: [
                  // 1. COPERTINA (Hero)
                  Hero(
                    tag: liveBook.id,
                    child: Container(
                      height: 280,
                      width: 190,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isRead
                                ? Colors.greenAccent.withOpacity(0.4)
                                : Colors.cyanAccent.withOpacity(0.3),
                            blurRadius: 30,
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(liveBook.thumbnailUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. TITOLI
                  Text(
                    liveBook.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    liveBook.author,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 3. STATS BAR (Componente)
                  BookStatsBar(book: liveBook),
                  const SizedBox(height: 25),

                  // 4. STATUS BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRead
                            ? const Color(0xFF1B5E20)
                            : Colors.cyanAccent,
                        foregroundColor: isRead ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () =>
                          _handleStatusToggle(liveBook, currentStatus),
                      icon: Icon(
                        isRead ? Icons.undo : Icons.check_circle_outline,
                      ),
                      label: Text(
                        isRead ? "COMPLETATO" : "SEGNA COME LETTO",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. AI SECTION (Componente)
                  AIAnalysisSection(
                    analysisText: storedAnalysis,
                    isAnalyzing: _isAnalyzing,
                    onAnalyzeTap: () => _handleAnalysis(liveBook),
                  ),

                  const SizedBox(height: 30),

                  // 6. SINOSSI
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "SINOSSI",
                      style: TextStyle(
                        color: Colors.white30,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    liveBook.description.isNotEmpty
                        ? liveBook.description
                        : "Nessuna descrizione.",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
