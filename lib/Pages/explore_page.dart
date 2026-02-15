import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import 'package:library_ai/services/pages_services/explore_service.dart';
import '../models/category_card.dart';
import 'search_page.dart'; // Assicurati che il nome del file sia corretto

class ExplorePage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  final ExploreService _exploreService = ExploreService();
  static const Color _themeColor = Colors.orangeAccent;

  ExplorePage({super.key, required this.mode, required this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final categories = _exploreService.getCategories(mode);
    final title = mode == AppMode.books ? "ESPLORA LIBRI" : "ESPLORA CINEMA";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            floating: true,
            pinned: true,
            expandedHeight: 120,
            elevation: 0,
            // Custom Leading per evitare collisioni
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: onOpenDrawer,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _themeColor.withOpacity(0.1),
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
                  delegate: UniversalSearchDelegate(
                    mode: mode,
                  ), // FIX: Usiamo quello universale
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => CategoryCard(category: categories[index]),
                childCount: categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
