import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/book.dart';
// IMPORTA LA LOGICA E I WIDGET
import '../services/pages_services/book_detail_logic.dart'; // Assicurati del percorso corretto
import '/models/book_widgets/book_stats_bar.dart';
import '../models/ai_analysis_section.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  // Istanziamo la logica
  final BookDetailLogic _logic = BookDetailLogic();

  bool _isAnalyzing = false;
  static const Color _brandColor = Colors.orangeAccent;

  // Wrapper per chiamare l'analisi e aggiornare il loading locale
  Future<void> _onAnalyzeTap(Book liveBook) async {
    setState(() => _isAnalyzing = true);
    await _logic.handleAnalysis(context, liveBook);
    if (mounted) setState(() => _isAnalyzing = false);
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
        String currentStatus = 'none';
        String? storedAnalysis;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          liveBook = Book.fromFirestore(data, widget.book.id);
          currentStatus = liveBook.status;
          storedAnalysis = liveBook.aiAnalysis;
        }

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
                // HEADER (Immagine)
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENUTO
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

                      // I DUE TASTI (Logica delegata al Service)
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              label: "DA LEGGERE",
                              icon: Icons.bookmark_add_outlined,
                              isActive: currentStatus == 'toread',
                              activeColor: _brandColor,
                              // CHIAMA LA LOGICA QUI
                              onTap: () => _logic.handleStatusAction(
                                context,
                                liveBook,
                                'toread',
                                currentStatus,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildActionButton(
                              label: "LETTO",
                              icon: Icons.check_circle_outline,
                              isActive: currentStatus == 'read',
                              activeColor: Colors.green,
                              // CHIAMA LA LOGICA QUI
                              onTap: () => _logic.handleStatusAction(
                                context,
                                liveBook,
                                'read',
                                currentStatus,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      AIAnalysisSection(
                        analysisText: storedAnalysis,
                        isAnalyzing: _isAnalyzing,
                        onAnalyzeTap: () => _onAnalyzeTap(liveBook),
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? activeColor
              : Colors.white.withOpacity(0.05),
          foregroundColor: isActive ? Colors.black : Colors.white,
          elevation: isActive ? 5 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isActive
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isActive ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}
