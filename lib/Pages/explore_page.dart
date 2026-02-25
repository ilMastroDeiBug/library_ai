import 'package:flutter/material.dart';
import '../../models/app_mode.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/explore_use_cases.dart';
import '../models/category_card.dart';
import 'search_page.dart';

class ExplorePage extends StatelessWidget {
  final AppMode mode;
  final bool isTvSeries; // <-- Aggiunto il controllo
  final VoidCallback onOpenDrawer;

  static const Color _brandColor = Colors.orangeAccent;
  static const Color _bgColor = Color(0xFF0A0A0C);

  const ExplorePage({
    super.key,
    required this.mode,
    this.isTvSeries = false, // <-- Gestiamo le Serie TV
    required this.onOpenDrawer,
  });

  String _getTitle() {
    if (mode == AppMode.books) return "Esplora Libri";
    return isTvSeries ? "Esplora Serie TV" : "Esplora Cinema";
  }

  @override
  Widget build(BuildContext context) {
    // Richiediamo i dati giusti in base alla combinazione Mode / isTvSeries
    final categories = sl<GetExploreCategoriesUseCase>().call(
      mode,
      isTvSeries: isTvSeries,
    );

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: _bgColor,
            floating: true,
            pinned: true,
            expandedHeight: 140,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: onOpenDrawer,
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 20,
                bottom: 16,
                right: 20,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    mode == AppMode.books
                        ? Icons.auto_stories
                        : Icons.movie_creation_rounded,
                    color: _brandColor.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () => showSearch(
                  context: context,
                  delegate: UniversalSearchDelegate(mode: mode),
                ),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161618),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "Cerca un titolo, regista o autore...",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => CategoryCard(
                  category: categories[index],
                  mode: mode,
                  isTvSeries: isTvSeries, // <-- Passiamolo alla card!
                ),
                childCount: categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
