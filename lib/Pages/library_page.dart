import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Necessario per l'effetto Glass (BackdropFilter)
import '../models/book_card.dart';
import '../models/book_model.dart';
import '../pages/settings_page.dart';
import '../models/app_mode.dart';

class LibraryPage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const LibraryPage({
    super.key,
    required this.mode,
    required this.onOpenDrawer,
  });

  // --- LOGICA DI ELIMINAZIONE (Invariata) ---
  Future<void> _deleteBook(BuildContext context, String bookId) async {
    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).delete();
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Dato rimosso dal database."),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
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
      }
    }
  }

  void _showDeleteDialog(BuildContext context, String bookId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur sullo sfondo
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
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
            "Rimuovere \"$title\" dalla libreria è un'azione irreversibile.",
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
              ),
              onPressed: () => _deleteBook(ctx, bookId),
              child: const Text("ELIMINA"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isBooks = mode == AppMode.books;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10), // Nero profondo, non grigio
      // FAB con bagliore
      floatingActionButton: isBooks
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: 'fab_library',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Usa il tasto + nella Home per aggiungere libri!",
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,

      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 350, // Più spazio per respirare
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0F0F10),
                leading: IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onOpenDrawer,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // 1. Sfondo con Gradiente "Architect" (Deep Blue -> Black)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF1A1F2C), // Blu scuro tecnico
                              Color(0xFF0F0F10), // Nero
                            ],
                          ),
                        ),
                      ),

                      // 2. Elementi decorativi di sfondo (Cerchi sfocati)
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.purpleAccent.withOpacity(0.05),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),

                      // 3. Contenuto Principale
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Header Profilo
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SettingsPage(),
                                      ),
                                    ),
                                    child: Hero(
                                      tag: 'profile_pic',
                                      child: Container(
                                        padding: const EdgeInsets.all(
                                          3,
                                        ), // Bordo doppio
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white12,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.grey[900],
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
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ARCHIVIO DI',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 10,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.displayName?.toUpperCase() ??
                                            "ARCHITECT",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Search Bar "Glass"
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 15),
                                      Icon(
                                        Icons.search,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        isBooks
                                            ? "Cerca nel database..."
                                            : "Cerca nella watchlist...",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Stats Cards (Nuovo Design)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  _buildStatCard(
                                    "IN CODA",
                                    "toread",
                                    Icons.hourglass_empty_rounded,
                                    Colors.orangeAccent,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatCard(
                                    isBooks ? "COMPLETATI" : "VISTI",
                                    "read",
                                    Icons.check_circle_outline_rounded,
                                    Colors.cyanAccent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F10),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: TabBar(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      indicatorColor: Colors.white,
                      indicatorWeight: 2,
                      indicatorSize: TabBarIndicatorSize
                          .label, // Linea solo sotto il testo
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
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

  // --- STAT CARD MODERNA ---
  Widget _buildStatCard(
    String label,
    String status,
    IconData icon,
    Color accentColor,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('userId', isEqualTo: user?.uid)
            .where('status', isEqualTo: status)
            .snapshots(),
        builder: (context, snapshot) {
          String count = "0";
          if (snapshot.hasData) count = snapshot.data!.docs.length.toString();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Gradiente sottile verticale
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF252525), const Color(0xFF181818)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icona con sfondo colorato glow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(height: 12),

                // Numero con Shader (Effetto Metallico/Luminoso)
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.white.withOpacity(0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    count,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Necessario per la mask
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
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

    if (!isBooks) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 60,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 15),
            Text(
              "Modulo Cinema in sviluppo...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Container(
      color: const Color(0xFF0F0F10), // Continuità sfondo
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
                    status == 'toread'
                        ? Icons.bookmark_add_outlined
                        : Icons.done_all_rounded,
                    size: 60,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    status == 'toread'
                        ? "Database vuoto.\nAggiungi nuovi input."
                        : "Nessun task completato.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              20,
              30,
              20,
              100,
            ), // Più padding in basso per il FAB
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68, // Leggermente più allungato
              crossAxisSpacing: 20,
              mainAxisSpacing: 25,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bookId = docs[index].id;

              final book = Book(
                id: bookId,
                title: data['title'] ?? 'N/D',
                author: data['author'] ?? 'Sconosciuto',
                thumbnailUrl: data['thumbnailUrl'] ?? '',
                description: data['description'] ?? '',
                pageCount: data['pageCount'],
                averageRating: data['averageRating'],
                ratingsCount: data['ratingsCount'],
              );

              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onLongPress: () =>
                    _showDeleteDialog(context, bookId, book.title),
                child: BookCard(book: book),
              );
            },
          );
        },
      ),
    );
  }
}
