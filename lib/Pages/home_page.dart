import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart'; // Assicurati di avere il modello Book
import '../models/book_card.dart'; // La card che abbiamo già creato
import '../models/book_section.dart'; // Le sezioni di Google
import 'search_page.dart'; // La pagina di ricerca

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // --- POPUP INSERIMENTO MANUALE (Invariato) ---
  void _showAddBookSheet(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController authorController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF232526),
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
              child: const Text("Salva nella Libreria"),
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
        fillColor: Colors.white.withOpacity(0.05),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookSheet(context),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF232526), Color(0xFF414345)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: Colors.cyanAccent),
                          SizedBox(width: 10),
                          Text(
                            "Cerca titolo, autore, ISBN...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- 2. AI HERO BANNER (La tua Prima Sezione) ---
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
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
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
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "CONSIGLIATO DALL'AI",
                                  style: TextStyle(
                                    color: Colors.white,
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
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- 3. I TUOI LIBRI IN CORSO (Seconda Sezione Richiesta) ---
                // Nota: Per ora mostriamo i libri 'toread' come "In Programma"
                // finché non creiamo lo status 'reading'.
                const UserBooksSection(
                  title: "🔥 La tua Coda di Lettura",
                  status: "toread",
                ),

                const SizedBox(height: 20),

                // --- 4. CATALOGO GOOGLE (Scalabile) ---
                // Qui lasciamo solo le categorie principali, le altre andranno in Esplora
                const BookSection(
                  title: "📖 Grandi Classici",
                  categoryQuery: "classics",
                ),
                const SizedBox(height: 10),
                const BookSection(
                  title: "🐉 Fantasy & Avventura",
                  categoryQuery: "fantasy",
                ),
                const SizedBox(height: 10),
                const BookSection(
                  title: "🧠 Crescita Personale",
                  categoryQuery: "self-help",
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- NUOVO COMPONENTE: UserBooksSection ---
// Questo widget è intelligente: invece di chiamare Google, chiama il TUO Firestore.
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
              // Icona freccia per dire "vai alla libreria"
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
            ],
          ),
        ),

        SizedBox(
          height: 200, // Altezza leggermente ridotta rispetto a Google
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('books')
                .where('userId', isEqualTo: user.uid)
                .where('status', isEqualTo: status)
                .orderBy('timestamp', descending: true)
                .limit(5) // Mostriamo solo i primi 5 recenti nella home
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                // Se non hai libri salvati, mostriamo un invito
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

                  // Usiamo BookCard ma ridimensionata leggermente
                  return Transform.scale(
                    scale: 0.9,
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
