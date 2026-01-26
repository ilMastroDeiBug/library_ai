import 'package:flutter/material.dart';
import 'search_page.dart';
import 'genre_result_page.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  // --- LA LISTA MAESTRA (VERSIONE PREMIUM DARK) ---
  static final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Fantasy',
      'id': 'fantasy',
      'icon': Icons.auto_awesome,
      'color': Color(0xFF4A148C), // Viola Imperiale scuro
    },
    {
      'name': 'Sci-Fi',
      'id': 'science fiction',
      'icon': Icons.rocket_launch,
      'color': Color(0xFF1A237E), // Blu Notte profondo
    },
    {
      'name': 'Horror',
      'id': 'horror',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Color(0xFF880E4F), // Rosso Sangue/Bordeaux
    },
    {
      'name': 'Thriller',
      'id': 'thriller',
      'icon': Icons.fingerprint,
      'color': Color(0xFF263238), // Grigio Antracite
    },
    {
      'name': 'Storici',
      'id': 'history',
      'icon': Icons.account_balance,
      'color': Color(0xFF3E2723), // Bronzo/Marrone scuro
    },
    {
      'name': 'Biografie',
      'id': 'biography',
      'icon': Icons.person,
      'color': Color(0xFF004D40), // Verde Petrolio scuro
    },
    {
      'name': 'Manga',
      'id': 'manga',
      'icon': Icons.import_contacts,
      'color': Color(0xFFE65100), // Arancione Bruciato (meno neon)
    },
    {
      'name': 'Romantici',
      'id': 'romance',
      'icon': Icons.favorite,
      'color': Color(0xFF880E4F), // Rosa Antico scuro
    },
    {
      'name': 'Tech & Code',
      'id': 'computers',
      'icon': Icons.terminal,
      'color': Color(0xFF1B5E20), // Verde Foresta
    },
    {
      'name': 'Psicologia',
      'id': 'psychology',
      'icon': Icons.psychology,
      'color': Color(0xFF37474F), // Blu-Grigio scuro
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232526),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header con Ricerca
          SliverAppBar(
            backgroundColor: const Color(0xFF232526),
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "Esplora Mondi",
                style: TextStyle(
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
                      // Gradiente dell'header molto più sottile e scuro
                      Colors.black54.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.cyanAccent),
                onPressed: () => showSearch(
                  context: context,
                  delegate: BookSearchDelegate(),
                ),
              ),
            ],
          ),

          // 2. La Griglia Automatica
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 colonne
                childAspectRatio:
                    1.6, // Leggermente più schiacciate ed eleganti
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final cat = _categories[index];
                return _buildCategoryCard(context, cat);
              }, childCount: _categories.length),
            ),
          ),

          // Spazio extra in fondo per la BottomBar
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // Il "BluePrint" della Card
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
          // Gradiente più sofisticato: dal colore scuro al quasi nero
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category['color'], // Colore base scuro
              Color(0xFF232526), // Sfuma verso il colore di sfondo dell'app
            ],
          ),
          borderRadius: BorderRadius.circular(
            16,
          ), // Bordi un po' meno rotondi, più seri
          boxShadow: [
            BoxShadow(
              color: Colors.black45, // Ombra nera, non colorata
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          // Bordo sottilissimo per dare definizione
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          children: [
            // Icona grande decorativa (molto trasparente)
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                category['icon'],
                size: 90,
                color: Colors.white.withOpacity(
                  0.05,
                ), // Quasi invisibile, solo texture
              ),
            ),
            // Contenuto
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icona piccola accentata
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

                  // Nome Categoria
                  Text(
                    category['name']
                        .toUpperCase(), // Maiuscolo è più "editoriale"
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2, // Spaziatura per eleganza
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
