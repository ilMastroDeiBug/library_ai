import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import 'search_page.dart';
// Import Widget Modulari
import '../models/add_book_sheet.dart';
import '../models/user_books_section.dart';
import '../models/book_section.dart'; // Questo è il widget che usa OpenLibraryService

class HomePage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const HomePage({super.key, required this.mode, required this.onOpenDrawer});

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => const AddBookSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed: onOpenDrawer,
        ),
      ),
      floatingActionButton: mode == AppMode.books
          ? FloatingActionButton(
              heroTag: 'fab_home',
              onPressed: () => _showAddSheet(context),
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
                // 1. SEARCH BAR
                _buildSearchBar(context),
                const SizedBox(height: 30),

                // 2. CONTENUTO
                if (mode == AppMode.books) ...[
                  // Banner AI
                  _buildAIBannerPlaceholder(),
                  const SizedBox(height: 30),

                  // I TUOI LIBRI (La tua coda personale)
                  UserBooksSection(
                    title: "🔥 La tua Coda di Lettura",
                    status: "toread",
                  ),
                  const SizedBox(height: 20),

                  // --- INIZIO CATALOGO ESPANSO ---

                  // 1. I Grandi Classici e Bestsellers (Generalista)
                  const BookSection(
                    title: "🏆 Bestsellers & Classici",
                    categoryQuery:
                        "fiction", // 'fiction' su OpenLib tira fuori i grandi romanzi
                  ),
                  const SizedBox(height: 10),

                  // 2. Romance (Include il 'Romance' richiesto)
                  const BookSection(
                    title: "💘 Romance & Love Stories",
                    categoryQuery: "romance",
                  ),
                  const SizedBox(height: 10),

                  // 3. Thriller e Azione
                  const BookSection(
                    title: "🔪 Thriller & Suspense",
                    categoryQuery: "thriller",
                  ),
                  const SizedBox(height: 10),

                  // 4. Fantasy
                  const BookSection(
                    title: "🐉 Fantasy",
                    categoryQuery: "fantasy",
                  ),
                  const SizedBox(height: 10),

                  // 5. Sci-Fi
                  const BookSection(
                    title: "🚀 Sci-Fi & Cyberpunk",
                    categoryQuery: "science_fiction",
                  ),
                  const SizedBox(height: 10),

                  // 6. Avventura e Azione
                  const BookSection(
                    title: "Avventura",
                    categoryQuery: "adventure",
                  ),
                  const SizedBox(height: 10),

                  // 7. Horror
                  const BookSection(title: "Horror", categoryQuery: "horror"),
                  const SizedBox(height: 10),

                  // 8. Gialli / Mistery
                  const BookSection(
                    title: "Gialli & Mistery",
                    categoryQuery: "mystery",
                  ),
                  const SizedBox(height: 10),

                  // 9. Storici
                  const BookSection(
                    title: "🏛️ Romanzi Storici",
                    categoryQuery: "historical_fiction",
                  ),
                  const SizedBox(height: 10),

                  // 10. Crescita Personale
                  const BookSection(
                    title: "🧠 Mindset & Crescita",
                    categoryQuery: "self_help",
                  ),
                ] else ...[
                  _buildMoviesPlaceholder(),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () =>
            showSearch(context: context, delegate: BookSearchDelegate()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
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
    );
  }

  // Placeholder per il banner AI (copia qui il codice del container viola se non lo estrai)
  Widget _buildAIBannerPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text("Banner AI", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildMoviesPlaceholder() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Text(
          "Cinema in arrivo...",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
