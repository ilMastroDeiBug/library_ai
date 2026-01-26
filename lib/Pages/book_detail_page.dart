import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../ai_service.dart';

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

  // --- ANALISI AI ---
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

  // --- TOGGLE STATUS (SALVATAGGIO SICURO) ---
  Future<void> _toggleReadStatus(Book liveBook, String currentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Se è 'read' diventa 'toread', altrimenti diventa 'read'
    final newStatus = currentStatus == 'read' ? 'toread' : 'read';

    try {
      // USIAMO .set CON MERGE: Crea il libro se non esiste, lo aggiorna se esiste.
      await FirebaseFirestore.instance.collection('books').doc(liveBook.id).set(
        {
          'userId': user.uid,
          'title': liveBook.title,
          'author': liveBook.author,
          'description': liveBook.description,
          'thumbnailUrl': liveBook.thumbnailUrl,
          'status': newStatus,
          'timestamp':
              FieldValue.serverTimestamp(), // Aggiorna l'orario per l'ordinamento
        },
        SetOptions(merge: true),
      ); // <--- LA CHIAVE È QUI: merge true non sovrascrive tutto se esiste già

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
        // --- LOGICA DATI VIVI ---
        Book liveBook = widget.book;
        String currentStatus = 'toread'; // Default se il libro non è nel DB

        // Se il libro ESISTE nel DB, prendiamo i dati reali
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
        // Se NON ESISTE (es. arrivi dalla ricerca), usiamo i dati di widget.book e status 'toread'

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
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF0F3460),
                ], // Deep Blue Theme
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
                      // Passiamo liveBook e currentStatus alla funzione
                      onPressed: () =>
                          _toggleReadStatus(liveBook, currentStatus),
                      icon: Icon(
                        isRead ? Icons.undo : Icons.check_circle_outline,
                      ),
                      label: Text(
                        isRead
                            ? "COMPLETATO (Torna indietro)"
                            : "SEGNA COME LETTO", // Se non esiste, cliccando qui lo crea come letto
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  // Se il libro non è ancora letto, mostriamo anche l'opzione "Aggiungi a Da Leggere"
                  // opzionale, per chiarezza UI se uno vuole solo salvarlo senza leggerlo subito
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
                        // Anche questo salva il libro, ma con status 'toread' esplicitamente
                        onPressed: () => _toggleReadStatus(liveBook, 'read'),
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text("AGGIUNGI A 'DA LEGGERE'"),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- PULSANTE AI ---
                  _buildAIButton(liveBook),

                  const SizedBox(height: 30),

                  // --- RISULTATO AI ---
                  if (_aiResult != null) _buildAIResultCard(),

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
    final int score = _aiResult!['compatibility'] ?? 0;
    Color scoreColor = score > 75
        ? Colors.greenAccent
        : (score > 40 ? Colors.orangeAccent : Colors.redAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.5)),
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
            _aiResult!['reason'] ?? "Nessun motivo specificato.",
            style: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          ...(_aiResult!['key_takeaways'] as List<dynamic>).map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Colors.cyanAccent),
                  Expanded(
                    child: Text(
                      t.toString(),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
