import 'package:flutter/material.dart';
import 'search_page.dart';
import 'genre_result_page.dart';
import '../models/app_mode.dart'; // <--- Assicurati che l'Enum sia importato

class ExplorePage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback
  onOpenDrawer; // <--- 1. AGGIUNTO: Il ricevitore del comando

  const ExplorePage({
    super.key,
    required this.mode,
    required this.onOpenDrawer, // <--- 2. AGGIUNTO: Obbligatorio nel costruttore
  });

  // --- LISTA LIBRI ---
  static final List<Map<String, dynamic>> _bookCategories = [
    {
      'name': 'Fantasy',
      'id': 'fantasy',
      'icon': Icons.auto_awesome,
      'color': const Color(0xFF4A148C),
    },
    {
      'name': 'Sci-Fi',
      'id': 'science fiction',
      'icon': Icons.rocket_launch,
      'color': const Color(0xFF1A237E),
    },
    {
      'name': 'Horror',
      'id': 'horror',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': const Color(0xFF880E4F),
    },
    {
      'name': 'Thriller',
      'id': 'thriller',
      'icon': Icons.fingerprint,
      'color': const Color(0xFF263238),
    },
    {
      'name': 'Storici',
      'id': 'history',
      'icon': Icons.account_balance,
      'color': const Color(0xFF3E2723),
    },
    {
      'name': 'Biografie',
      'id': 'biography',
      'icon': Icons.person,
      'color': const Color(0xFF004D40),
    },
    {
      'name': 'Manga',
      'id': 'manga',
      'icon': Icons.import_contacts,
      'color': const Color(0xFFE65100),
    },
    {
      'name': 'Romantici',
      'id': 'romance',
      'icon': Icons.favorite,
      'color': const Color(0xFF880E4F),
    },
    {
      'name': 'Tech',
      'id': 'computers',
      'icon': Icons.terminal,
      'color': const Color(0xFF1B5E20),
    },
    {
      'name': 'Psicologia',
      'id': 'psychology',
      'icon': Icons.psychology,
      'color': const Color(0xFF37474F),
    },
  ];

  // --- LISTA FILM ---
  static final List<Map<String, dynamic>> _movieCategories = [
    {
      'name': 'Azione',
      'id': '28',
      'icon': Icons.local_fire_department,
      'color': const Color(0xFFB71C1C),
    },
    {
      'name': 'Commedia',
      'id': '35',
      'icon': Icons.sentiment_very_satisfied,
      'color': const Color(0xFFF57F17),
    },
    {
      'name': 'Drammatici',
      'id': '18',
      'icon': Icons.theater_comedy,
      'color': const Color(0xFF0D47A1),
    },
    {
      'name': 'Sci-Fi',
      'id': '878',
      'icon': Icons.rocket,
      'color': const Color(0xFF1A237E),
    },
    {
      'name': 'Horror',
      'id': '27',
      'icon': Icons.bug_report,
      'color': const Color(0xFF212121),
    },
    {
      'name': 'Animazione',
      'id': '16',
      'icon': Icons.animation,
      'color': const Color(0xFF006064),
    },
    {
      'name': 'Documentari',
      'id': '99',
      'icon': Icons.videocam,
      'color': const Color(0xFF33691E),
    },
    {
      'name': 'Thriller',
      'id': '53',
      'icon': Icons.fingerprint,
      'color': const Color(0xFF263238),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Scegliamo la lista giusta in base alla modalità
    final currentCategories = mode == AppMode.books
        ? _bookCategories
        : _movieCategories;
    final title = mode == AppMode.books ? "Esplora Libri" : "Esplora Cinema";

    return Scaffold(
      backgroundColor: const Color(0xFF232526),

      // NOTA: NIENTE DRAWER QUI! Usiamo quello del padre.
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF232526),
            floating: true,
            pinned: true,
            expandedHeight: 120,

            // --- 3. TASTO MENU COLLEGATO ---
            leading: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed:
                  onOpenDrawer, // <--- Cliccando qui si apre il menu del NavigationHub
            ),

            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: mode == AppMode.books
                      ? Colors.cyanAccent
                      : Colors.orangeAccent,
                ),
                onPressed: () => showSearch(
                  context: context,
                  delegate:
                      BookSearchDelegate(), // TODO: MovieSearchDelegate in futuro
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final cat = currentCategories[index];
                return _buildCategoryCard(context, cat);
              }, childCount: currentCategories.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenreResultPage(
              categoryName: category['name'],
              categoryId: category['id'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [category['color'], const Color(0xFF232526)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                category['icon'],
                size: 90,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category['icon'],
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                  Text(
                    category['name'].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
