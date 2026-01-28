import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_card.dart';
import '../models/book_model.dart';
// NOTA: side_menu rimosso perché non lo usiamo qui dentro
import '../pages/settings_page.dart';
import '../models/app_mode.dart'; // <--- Enum necessario

class LibraryPage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer; // <--- IL TELECOMANDO

  const LibraryPage({
    super.key,
    required this.mode,
    required this.onOpenDrawer, // <--- OBBLIGATORIO
  });

  // --- LOGICA DI ELIMINAZIONE (TUA LOGICA ORIGINALE) ---
  Future<void> _deleteBook(BuildContext context, String bookId) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
      if (context.mounted) {
        Navigator.of(context).pop();
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
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Errore: $e")));
      }
    }
  }

  void _showDeleteDialog(BuildContext context, String bookId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
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
    // Logica per decidere se mostrare libri o film (placeholder per ora)
    final isBooks = mode == AppMode.books;

    return Scaffold(
      backgroundColor: const Color(
        0xFF121212,
      ), // Sfondo Grigio scuro (Quasi nero)
      // --- ATTENZIONE: NIENTE DRAWER QUI! ---
      // Il drawer è gestito dal padre (NavigationHub)

      // FAB (Mostrato solo se siamo nei Libri)
      floatingActionButton: isBooks
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1), // Ombra più sottile
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor:
                    Colors.white, // FAB Bianco per contrasto massimo
                foregroundColor: Colors.black,
                elevation: 0,
                onPressed: () {
                  // Qui puoi mostrare un messaggio o navigare alla pagina di aggiunta
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Usa il tasto + nella Home per aggiungere libri!",
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add, size: 30),
              ),
            )
          : null,

      // BODY CON TAB CONTROLLER
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 340,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF121212),

                // --- 2. TASTO MENU FORZATO BIANCO (CON TELECOMANDO) ---
                leading: IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onOpenDrawer, // <--- USA IL TELECOMANDO
                ),

                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        // Gradiente Grigio Sofisticato
                        colors: [Color(0xFF2C2C2C), Color(0xFF121212)],
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
                                    // --- 3. IMMAGINE PROFILO CLICCABILE ---
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SettingsPage(),
                                          ),
                                        );
                                      },
                                      child: Hero(
                                        tag: 'profile_pic',
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white24,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.grey[800],
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // 2. Search Bar
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1E1E1E,
                              ), // Grigio leggermente più chiaro
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.white54),
                                const SizedBox(width: 10),
                                Text(
                                  isBooks
                                      ? "Cerca libreria..."
                                      : "Cerca watchlist...",
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
                                _buildStatCard(
                                  isBooks ? "Letti" : "Visti",
                                  "read",
                                  Icons.done_all,
                                ),
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
                      color: const Color(0xFF121212),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: TabBar(
                      indicatorColor: Colors.white, // Indicatore bianco
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: [
                        const Tab(text: "DA LEGGERE"),
                        Tab(text: isBooks ? "COMPLETATI" : "VISTI"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildBookGrid(context, status: "toread"),
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
              color: const Color(0xFF1E1E1E), // Card Grigia
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white70, size: 20),
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

  Widget _buildBookGrid(BuildContext context, {required String status}) {
    final user = FirebaseAuth.instance.currentUser;
    final isBooks = mode == AppMode.books;

    // Se siamo in modalità FILM, mostriamo un placeholder (per ora)
    if (!isBooks) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              size: 60,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 10),
            Text(
              "Watchlist in arrivo...",
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Container(
      color: const Color(0xFF121212), // Sfondo griglia grigio scuro
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
              child: CircularProgressIndicator(color: Colors.white),
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
              final bookId = docs[index].id;

              final book = Book(
                id: bookId,
                title: data['title'] ?? 'Sconosciuto',
                author: data['author'] ?? 'Sconosciuto',
                thumbnailUrl: data['thumbnailUrl'] ?? '',
                description: data['description'] ?? '',
              );

              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onLongPress: () {
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
