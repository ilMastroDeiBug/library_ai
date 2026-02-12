import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import 'search_page.dart';
// Import Widget Modulari
import '/models/book_widgets/add_book_sheet.dart';
import '../models/user_books_section.dart';
// Importa il Builder
import '../models/home_widgets/home_content_builders.dart';

class HomePage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  static const Color _brandColor = Colors.orangeAccent;

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
          // QUI CAMBIA IL COLORE: da white a _brandColor (o Colors.orangeAccent)
          icon: const Icon(
            Icons.menu_rounded,
            color: Colors.orangeAccent, // <--- Modifica applicata qui
            size: 28,
          ),
          onPressed: onOpenDrawer,
        ),
      ),
      floatingActionButton: mode == AppMode.books
          ? FloatingActionButton(
              heroTag: 'fab_home',
              onPressed: () => _showAddSheet(context),
              backgroundColor: _brandColor,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
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

                // 2. CONTENUTO DINAMICO
                if (mode == AppMode.books) ...[
                  // --- LIBRI ---
                  _buildAIBannerPlaceholder(),
                  const SizedBox(height: 30),

                  // Sezione Utente
                  UserBooksSection(
                    title: "La tua Coda di Lettura",
                    status: "toread",
                  ),

                  // Il Catalogo Generato dal Builder
                  ...HomeContentBuilder.buildBookContent(),
                ] else ...[
                  // --- CINEMA ---
                  _buildAIBannerPlaceholder(),
                  const SizedBox(height: 30),

                  // Sezione Utente
                  UserBooksSection(
                    title: "Da Vedere Stasera",
                    status: "towatch",
                  ),

                  // Il Catalogo Generato dal Builder
                  ...HomeContentBuilder.buildMovieContent(),
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _brandColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: _brandColor),
              const SizedBox(width: 10),
              Text(
                mode == AppMode.books
                    ? "Cerca titolo, autore..."
                    : "Cerca film, attori...",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIBannerPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orangeAccent.withOpacity(0.2),
              const Color(0xFF1E1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.orangeAccent,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                "ANALISI INTELLIGENTE",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
