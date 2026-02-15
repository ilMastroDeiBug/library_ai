import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '../models/book_widgets/add_book_sheet.dart';
import '../models/user_books_section.dart';
import '../models/home_widgets/home_content_builders.dart';
import '../models/home_widgets/home_cinema_switcher.dart'; // Importa lo switcher
import 'search_page.dart';

class HomePage extends StatefulWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const HomePage({super.key, required this.mode, required this.onOpenDrawer});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _brandColor = Colors.orangeAccent;

  // Stato per lo switcher Film/Serie
  CinemaType _selectedCinemaType = CinemaType.movies;

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
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: widget.onOpenDrawer,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_rounded, color: _brandColor, size: 24),
          ),
        ),
      ),
      floatingActionButton: widget.mode == AppMode.books
          ? FloatingActionButton(
              heroTag: 'fab_home',
              onPressed: () => _showAddSheet(context),
              backgroundColor: _brandColor,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF121212)),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildSearchBar(context),

                // --- SWITCHER TIKTOK STYLE (Solo in Cinema Mode) ---
                if (widget.mode == AppMode.movies)
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: HomeCinemaSwitcher(
                      selectedType: _selectedCinemaType,
                      onTypeChanged: (newType) {
                        setState(() {
                          _selectedCinemaType = newType;
                        });
                      },
                    ),
                  ),

                const SizedBox(height: 10),

                // 2. HERO BANNER (Dinamico in base allo switcher)
                HomeContentBuilder.buildHeroBanner(
                  widget.mode,
                  cinemaType: _selectedCinemaType,
                ),

                const SizedBox(height: 30),

                // 3. CONTENUTO CONDIZIONALE
                if (widget.mode == AppMode.books) ...[
                  const UserBooksSection(
                    title: "In coda di lettura",
                    status: "toread",
                  ),
                  ...HomeContentBuilder.buildBookContent(),
                ] else ...[
                  // CORREZIONE: Usiamo buildCinemaContent passando il tipo
                  ...HomeContentBuilder.buildCinemaContent(
                    type: _selectedCinemaType,
                  ),
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
    // Placeholder dinamico
    String placeholder = "Cerca...";
    if (widget.mode == AppMode.books) {
      placeholder = "Cerca titolo, autore...";
    } else {
      placeholder = _selectedCinemaType == CinemaType.movies
          ? "Cerca film, attori..."
          : "Cerca serie TV...";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => showSearch(
          context: context,
          delegate: UniversalSearchDelegate(mode: widget.mode),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: _brandColor, size: 20),
              const SizedBox(width: 12),
              Text(
                placeholder,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
