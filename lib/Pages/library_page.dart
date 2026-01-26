import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_card.dart';
import '../models/book_model.dart';
// import '../pages/add_book_page.dart'; // Scommenta quando avrai la pagina

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  Future<void> _signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Errore logout Google: $e");
    }
    await FirebaseAuth.instance.signOut();
  }

  // --- LOGICA DI ELIMINAZIONE ---
  Future<void> _deleteBook(BuildContext context, String bookId) async {
    try {
      // 1. Elimina da Firestore
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();

      // 2. Chiudi il dialog
      Navigator.of(context).pop();

      // 3. Mostra conferma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Libro eliminato per sempre."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Errore: $e")));
    }
  }

  // --- DIALOG DI CONFERMA (Stile Dark/Glass) ---
  void _showDeleteDialog(BuildContext context, String bookId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E), // Blu scuro profondo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Row(
          children: const [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 10),
            Text("Eliminare?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "Sei sicuro di voler rimuovere \"$title\" dalla tua libreria?\nQuesta azione è irreversibile.",
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "ANNULLA",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _deleteBook(ctx, bookId),
            child: const Text("ELIMINA"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),

      // FAB (Aggiungi)
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          onPressed: () {
            // TODO: Link alla pagina AddBookPage
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Presto potrai aggiungere libri!")),
            );
          },
          child: const Icon(Icons.add, size: 30),
        ),
      ),

      // BODY CON NESTED SCROLL
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 340,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1A1A2E),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0F3460), Color(0xFF1A1A2E)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. Profilo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Hero(
                                      tag: 'profile_pic',
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.cyanAccent,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.cyanAccent
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.black,
                                          backgroundImage:
                                              user?.photoURL != null
                                              ? NetworkImage(user!.photoURL!)
                                              : null,
                                          child: user?.photoURL == null
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Bentornato,',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          user?.displayName ?? "Architect",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white54,
                                  ),
                                  onPressed: _signOut,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // 2. Search
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Colors.cyanAccent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Cerca nella tua libreria...",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // 3. Stats Reali
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                _buildStatCard(
                                  "Da Leggere",
                                  "toread",
                                  Icons.bookmark_border,
                                ),
                                const SizedBox(width: 15),
                                _buildStatCard("Letti", "read", Icons.done_all),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: const TabBar(
                      indicatorColor: Colors.cyanAccent,
                      indicatorWeight: 3,
                      labelColor: Colors.cyanAccent,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: [
                        Tab(text: "DA LEGGERE"),
                        Tab(text: "COMPLETATI"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildBookGrid(context, status: "toread"), // Passiamo il context
              _buildBookGrid(context, status: "read"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String status, IconData icon) {
    final user = FirebaseAuth.instance.currentUser;
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('userId', isEqualTo: user?.uid)
            .where('status', isEqualTo: status)
            .snapshots(),
        builder: (context, snapshot) {
          String count = "...";
          if (snapshot.hasData) count = snapshot.data!.docs.length.toString();
          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.cyanAccent, size: 20),
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- GRIGLIA AGGIORNATA ---
  Widget _buildBookGrid(BuildContext context, {required String status}) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Container(
      color: const Color(0xFF1A1A2E),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: status)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    status == 'toread'
                        ? "La tua lista è vuota.\nCerca ispirazione!"
                        : "Nessuna lettura completata.\nInizia il viaggio.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bookId = docs[index].id; // Ci serve l'ID per cancellare!

              final book = Book(
                id: bookId,
                title: data['title'] ?? 'Sconosciuto',
                author: data['author'] ?? 'Sconosciuto',
                thumbnailUrl: data['thumbnailUrl'] ?? '',
                description: data['description'] ?? '',
              );

              // *** QUI AGGIUNGIAMO IL RILEVATORE DI GESTI ***
              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onLongPress: () {
                  // Vibrazione leggera (opzionale, richiede pacchetto services)
                  // HapticFeedback.mediumImpact();
                  _showDeleteDialog(context, bookId, book.title);
                },
                child: BookCard(book: book),
              );
            },
          );
        },
      ),
    );
  }
}
