import 'package:flutter/material.dart';
import 'search_page.dart';
import '../models/app_mode.dart';
import 'package:library_ai/services/pages_services/explore_service.dart';
import '../models/category_card.dart';

class ExplorePage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  final ExploreService _exploreService = ExploreService();

  // UNICO COLORE PER TUTTO (Style Architect)
  static const Color _themeColor = Colors.orangeAccent;

  ExplorePage({super.key, required this.mode, required this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final categories = _exploreService.getCategories(mode);
    final title = mode == AppMode.books ? "Esplora Libri" : "Esplora Cinema";

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Sfondo uniforme alla Home
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            floating: true,
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: onOpenDrawer,
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900, // Font più spesso
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1.5, // Spaziatura cinematografica
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _themeColor.withOpacity(0.15), // Tocco di giallo in alto
                      const Color(0xFF121212),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: _themeColor),
                onPressed: () => showSearch(
                  context: context,
                  delegate: BookSearchDelegate(),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6, // Formato Wide
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return CategoryCard(category: categories[index]);
              }, childCount: categories.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
