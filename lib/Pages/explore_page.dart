import 'package:flutter/material.dart';
import 'search_page.dart';
import '../models/app_mode.dart';
import 'package:library_ai/services/pages_services/explore_service.dart'; // Import Service
import '../models/category_card.dart'; // Import Widget

class ExplorePage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  // Istanziamo il service
  final ExploreService _exploreService = ExploreService();

  ExplorePage({super.key, required this.mode, required this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    // 1. Recuperiamo i dati dal Service (Backend Logico)
    final categories = _exploreService.getCategories(mode);
    final title = mode == AppMode.books ? "Esplora Libri" : "Esplora Cinema";
    final themeColor = mode == AppMode.books
        ? Colors.cyanAccent
        : Colors.orangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF232526),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF232526),
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
                icon: Icon(Icons.search, color: themeColor),
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
                childAspectRatio: 1.6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                // 2. Usiamo il componente grafico (Mattoncino)
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
