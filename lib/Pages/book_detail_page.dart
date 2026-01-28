import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/ai_service.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final AIService _aiService = AIService();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aiResult;

  // --- TEST DI CONNESSIONE (MVP) ---
  Future<void> _runConnectionTest() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Test connessione in corso..."),
        duration: Duration(seconds: 1),
      ),
    );

    // Chiama la funzione pingAI del service
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
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ),
          ],
        ),
      );
    }
  }

  // --- ANALISI REALE ---
  Future<void> _analyzeBook(Book liveBook) async {
    setState(() => _isAnalyzing = true);

    const userProfile =
        "Sono un ragazzo di 16 anni, ambizioso, studio sviluppo Full Stack, "
        "pratico MMA, ho una mentalità da Architect e voglio ottimizzare la mia crescita.";

    final result = await _aiService.analyzeBook(
      title: liveBook.title,
      author: liveBook.author,
      userProfile: userProfile,
    );

    if (mounted) {
      setState(() {
        _aiResult = result;
        _isAnalyzing = false;
      });
    }
  }

  // --- TOGGLE STATUS (Firebase) ---
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
            'status': newStatus,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'read'
                  ? "Libro completato! Salvato in libreria."
                  : "Libro spostato in 'Da Leggere'.",
            ),
            backgroundColor: newStatus == 'read'
                ? Colors.green
                : Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Errore aggiornamento status: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Errore: $e")));
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

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          currentStatus = data['status'] ?? 'toread';

          liveBook = Book(
            id: widget.book.id,
            title: data['title'] ?? widget.book.title,
            author: data['author'] ?? widget.book.author,
            thumbnailUrl: data['thumbnailUrl'] ?? widget.book.thumbnailUrl,
            description: data['description'] ?? widget.book.description,
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
                        child: Stack(
                          children: [
                            if (isRead)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- TITOLO E AUTORE ---
                  Text(
                    liveBook.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
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
                  const SizedBox(height: 30),

                  // --- PULSANTE TOGGLE STATUS ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRead
                            ? const Color(0xFF1B5E20)
                            : Colors.cyanAccent,
                        foregroundColor: isRead ? Colors.white : Colors.black,
                        elevation: 10,
                        shadowColor: isRead
                            ? Colors.greenAccent.withOpacity(0.4)
                            : Colors.cyanAccent.withOpacity(0.4),
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
                        isRead
                            ? "COMPLETATO (Torna indietro)"
                            : "SEGNA COME LETTO",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  if (!isRead) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => _toggleReadStatus(liveBook, 'read'),
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text("AGGIUNGI A 'DA LEGGERE'"),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- PULSANTE AI ---
                  _buildAIButton(liveBook),

                  const SizedBox(height: 15),

                  // --- TASTO MVP: ROSSO E VISIBILE ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(
                          0.2,
                        ), // Rosso sfondo
                        foregroundColor: Colors.redAccent, // Rosso testo
                        side: const BorderSide(
                          color: Colors.redAccent,
                        ), // Bordo Rosso
                      ),
                      onPressed: _runConnectionTest,
                      child: const Text("TEST CONNESSIONE (MVP) - CLICCA QUI"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- RISULTATO AI ---
                  _buildAIResultCard(),

                  // --- DESCRIZIONE ---
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
                        : "Nessuna descrizione disponibile.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        onPressed: _isAnalyzing ? null : () => _analyzeBook(liveBook),
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
          _isAnalyzing ? "INTERROGANDO GEMINI..." : "ANALISI COMPATIBILITÀ AI",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAIResultCard() {
    if (_aiResult == null) return const SizedBox.shrink();

    final int score = _aiResult!['compatibility'] ?? 0;
    final String reason =
        _aiResult!['reason'] ?? "Nessuna motivazione fornita.";
    final List<dynamic> takeaways =
        _aiResult!['key_takeaways'] ?? ["Dati non disponibili"];
    final String actionPlan =
        _aiResult!['action_plan'] ?? "Nessun piano d'azione.";

    Color scoreColor = score > 75
        ? Colors.greenAccent
        : (score > 40 ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "VERDETTO ARCHITECT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scoreColor),
                ),
                child: Text(
                  "$score%",
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            reason,
            style: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),

          // Mappatura takeaways
          ...takeaways.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Action Plan Box
          if (actionPlan.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.rocket_launch,
                    color: Colors.cyanAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MISSIONE:",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          actionPlan,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
