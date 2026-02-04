import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/ai_service.dart';
import '../Pages/reviews_page.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final AIService _aiService = AIService();
  bool _isAnalyzing = false;

  // --- LOGICA VISIVA STELLE (Full, Half, Empty) ---
  // Questo metodo calcola matematicamente quali icone mostrare
  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        // Stella Piena
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 16));
      } else if (rating >= i - 0.5) {
        // Mezza Stella
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 16));
      } else {
        // Stella Vuota
        stars.add(
          Icon(
            Icons.star_border,
            color: Colors.white.withOpacity(0.3),
            size: 16,
          ),
        );
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  // --- TEST CONNESSIONE (MVP) ---
  Future<void> _runConnectionTest() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Test connessione AI in corso..."),
        duration: Duration(seconds: 1),
      ),
    );
    final result = await _aiService.pingAI();
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            "Risultato Test",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(result, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  // --- ANALISI CON SALVATAGGIO ---
  Future<void> _analyzeAndSaveBook(Book liveBook) async {
    setState(() => _isAnalyzing = true);
    // Nota: Qui potresti voler rendere dinamico il profilo utente in futuro
    const userProfile = "Sono un ragazzo di 16 anni, ambizioso...";

    final resultText = await _aiService.analyzeBook(
      title: liveBook.title,
      author: liveBook.author,
      userProfile: userProfile,
    );
    try {
      await FirebaseFirestore.instance.collection('books').doc(liveBook.id).set(
        {'aiAnalysis': resultText},
        SetOptions(merge: true),
      );
    } catch (e) {
      print("Errore salvataggio analisi: $e");
    }
    if (mounted) setState(() => _isAnalyzing = false);
  }

  // --- TOGGLE STATUS ---
  Future<void> _toggleReadStatus(Book liveBook, String currentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final newStatus = currentStatus == 'read' ? 'toread' : 'read';

    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(liveBook.id)
          .set({
            'userId': user.uid,
            'title': liveBook.title,
            'author': liveBook.author,
            'description': liveBook.description,
            'thumbnailUrl': liveBook.thumbnailUrl,
            'pageCount': liveBook.pageCount,
            'averageRating': liveBook.averageRating,
            'ratingsCount': liveBook.ratingsCount,
            'status': newStatus,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

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
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Errore status: $e");
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

          liveBook = Book(
            id: widget.book.id,
            title: data['title'] ?? widget.book.title,
            author: data['author'] ?? widget.book.author,
            thumbnailUrl: data['thumbnailUrl'] ?? widget.book.thumbnailUrl,
            description: data['description'] ?? widget.book.description,
            pageCount: data['pageCount'] ?? widget.book.pageCount,
            averageRating: data['averageRating'] ?? widget.book.averageRating,
            ratingsCount: data['ratingsCount'] ?? widget.book.ratingsCount,
          );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- COPERTINA ---
                  Center(
                    child: Hero(
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
                              spreadRadius: 2,
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
                  const SizedBox(height: 30),

                  // --- TITOLO & AUTORE ---
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
                  Center(
                    child: Text(
                      liveBook.author,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- INFO BOX (Pagine & Recensioni Visive) ---
                  _buildInfoRow(context, liveBook),

                  const SizedBox(height: 25),

                  // --- TASTI STATUS ---
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
                          _toggleReadStatus(liveBook, currentStatus),
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

                  // --- AI LOGIC ---
                  if (storedAnalysis == null) _buildAIButton(liveBook),
                  if (storedAnalysis == null) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 0.5,
                          ),
                        ),
                        onPressed: _runConnectionTest,
                        child: const Text("TEST CONNESSIONE (MVP)"),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- BOX RISULTATO ---
                  if (storedAnalysis != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology, color: Colors.cyanAccent),
                              SizedBox(width: 10),
                              Text(
                                "VERDETTO DELL'ARCHITETTO",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 30),
                          Text(
                            storedAnalysis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),

                  // --- SINOSSI ---
                  const Text(
                    "SINOSSI",
                    style: TextStyle(
                      color: Colors.white30,
                      letterSpacing: 1.5,
                      fontSize: 12,
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

  // --- WIDGET RIGA INFO (AGGIORNATO CON STELLE VISIVE) ---
  Widget _buildInfoRow(BuildContext context, Book book) {
    final double rating = book.averageRating?.toDouble() ?? 0.0;
    final int count = book.ratingsCount ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        // Aggiungiamo un bordo sottile per definire meglio l'area
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      // IntrinsicHeight serve a far sì che il divisore verticale
      // prenda l'altezza del contenuto più alto (le due colonne)
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Pagine
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "LUNGHEZZA",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      book.pageCount != null ? "${book.pageCount}" : "-",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Divisore verticale
            Container(width: 1, color: Colors.white12),

            // 2. Recensioni (Cliccabile & Visiva)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewsPage(book: book),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "VALUTAZIONE",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Render Visivo delle Stelle
                  Row(
                    children: [
                      _buildStarRating(rating), // Chiama il metodo creato sopra
                      const SizedBox(width: 8),
                      Text(
                        rating > 0 ? rating.toStringAsFixed(1) : "N/D",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Contatore recensioni piccolo
                  Text(
                    "$count recensioni",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton(Book liveBook) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isAnalyzing ? null : () => _analyzeAndSaveBook(liveBook),
        icon: _isAnalyzing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.psychology, color: Colors.white),
        label: Text(
          _isAnalyzing ? "STO PENSANDO..." : "RICHIEDI ANALISI AI",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
