import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/book_card.dart';
import '../models/book_section.dart';
import '../models/app_mode.dart';
import 'search_page.dart';
// NOTA: Nessun import di SideMenu qui.

class HomePage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer; // Il telecomando per il menu

  const HomePage({super.key, required this.mode, required this.onOpenDrawer});

  // --- POPUP AGGIUNTA MANUALE ---
  void _showAddBookSheet(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController authorController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nuova Avventura (Manuale)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildInput(titleController, "Titolo del libro"),
            const SizedBox(height: 15),
            _buildInput(authorController, "Autore"),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty && user != null) {
                  await FirebaseFirestore.instance.collection('books').add({
                    'title': titleController.text,
                    'author': authorController.text,
                    'userId': user.uid,
                    'status': 'toread',
                    'category': 'Generico',
                    'thumbnailUrl': '',
                    'description': 'Aggiunto manualmente',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "Salva nella Libreria",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // NOTA: NIENTE DRAWER QUI. USIAMO QUELLO DEL PADRE.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed:
              onOpenDrawer, // <--- Cliccando qui, apre il menu del NavigationHub
        ),
      ),

      floatingActionButton: mode == AppMode.books
          ? FloatingActionButton(
              heroTag: 'fab_home',
              onPressed: () => _showAddBookSheet(context),
              backgroundColor: Colors.cyanAccent,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF2C2C2C)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. SEARCH BAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => showSearch(
                      context: context,
                      delegate: BookSearchDelegate(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: mode == AppMode.books
                                ? Colors.cyanAccent
                                : Colors.orangeAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            mode == AppMode.books
                                ? "Cerca titolo, autore..."
                                : "Cerca film, attori...",
                            style: const TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- 2. CONTENUTO DINAMICO ---
                if (mode == AppMode.books)
                  _buildBooksContent()
                else
                  _buildMoviesPlaceholder(),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CONTENUTO LIBRI ---
  // --- CONTENUTO LIBRI ---
  Widget _buildBooksContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. AI HERO BANNER (Invariato)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurpleAccent, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.auto_stories,
                    size: 150,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "CONSIGLIATO DALL'AI",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "L'Arte della Guerra",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Sun Tzu",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // 2. I TUOI LIBRI (Invariato)
        const UserBooksSection(
          title: "🔥 La tua Coda di Lettura",
          status: "toread",
        ),

        const SizedBox(height: 20),

        // --- NUOVE CATEGORIE AGGIUNTE ---

        // Usiamo "fiction" generico ma grazie al tuo filtro usciranno i più votati = Bestsellers
        const BookSection(
          title: "🏆 Bestsellers del Momento",
          categoryQuery: "fiction",
        ),
        const SizedBox(height: 10),

        const BookSection(
          title: "🕵️ Gialli & Misteri",
          categoryQuery: "mystery",
        ),
        const SizedBox(height: 10),

        const BookSection(
          title: "🔪 Thriller Adrenalinici",
          categoryQuery: "thriller",
        ),
        const SizedBox(height: 10),

        const BookSection(title: "💘 Romance & Love", categoryQuery: "romance"),
        const SizedBox(height: 10),

        // Le vecchie categorie (sempre valide)
        const BookSection(
          title: "🐉 Fantasy & Avventura",
          categoryQuery: "fantasy",
        ),
        const SizedBox(height: 10),

        const BookSection(
          title: "🧠 Crescita Personale",
          categoryQuery: "self-help",
        ),
      ],
    );
  }

  // --- PLACEHOLDER CINEMA ---
  Widget _buildMoviesPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Icon(
            Icons.movie_filter_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          const Text(
            "Sezione Cinema in Arrivo",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Stiamo cablando i servizi TMDB...",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

// --- USER BOOKS SECTION (Con Logica Firestore) ---
class UserBooksSection extends StatelessWidget {
  final String title;
  final String status;

  const UserBooksSection({
    super.key,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('books')
                .where('userId', isEqualTo: user.uid)
                .where('status', isEqualTo: status)
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Text(
                      "Nessun libro in lista.\nCerca e aggiungi il primo!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final book = Book(
                    id: docs[index].id,
                    title: data['title'] ?? '',
                    author: data['author'] ?? '',
                    thumbnailUrl: data['thumbnailUrl'] ?? '',
                    description: data['description'] ?? '',
                  );
                  return Transform.scale(
                    scale: 0.95,
                    alignment: Alignment.topLeft,
                    child: BookCard(book: book),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
