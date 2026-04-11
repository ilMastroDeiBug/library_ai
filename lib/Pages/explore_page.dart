import 'package:flutter/material.dart';
import '../../models/app_mode.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/explore_use_cases.dart';
import '../models/category_card.dart';
import '../models/home_widgets/home_cinema_switcher.dart'; // <-- IMPORTIAMO LO SWITCHER
import 'search_page.dart';

class ExplorePage extends StatefulWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const ExplorePage({
    super.key,
    required this.mode,
    required this.onOpenDrawer,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const Color _brandColor = Colors.orangeAccent;
  static const Color _bgColor = Color(0xFF0A0A0C);

  // STATO LOCALE: Ricorda se stiamo guardando Film o Serie TV
  CinemaType _selectedCinemaType = CinemaType.movies;

  // Getter per comodità
  bool get isTvSeries => _selectedCinemaType == CinemaType.tvSeries;

  String _getTitle() {
    if (widget.mode == AppMode.books) return "Esplora Libri";
    return isTvSeries ? "Esplora Serie TV" : "Esplora Cinema";
  }

  @override
  Widget build(BuildContext context) {
    // 1. Chiamiamo l'Use Case passando lo stato locale in tempo reale
    final categories = sl<GetExploreCategoriesUseCase>().call(
      widget.mode,
      isTvSeries: isTvSeries,
    );

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // APP BAR
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
              onPressed: widget.onOpenDrawer,
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
                    widget.mode == AppMode.books
                        ? Icons.auto_stories
                        : Icons.movie_creation_rounded,
                    color: _brandColor.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // ZONA CONTROLLI (Ricerca + Switcher)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // BARRA DI RICERCA
                  GestureDetector(
                    onTap: () => showSearch(
                      context: context,
                      delegate: UniversalSearchDelegate(mode: widget.mode),
                    ),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161618),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
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

                  // IL NOSTRO SWITCHER (Magia UX!)
                  // Appare solo se siamo nel lato Cinema dell'app
                  if (widget.mode == AppMode.movies)
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 5),
                      child: HomeCinemaSwitcher(
                        selectedType: _selectedCinemaType,
                        onTypeChanged: (newType) {
                          // Aggiorniamo lo stato: l'UI si ridisegna all'istante
                          // caricando le nuove categorie dal Repository
                          setState(() {
                            _selectedCinemaType = newType;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // GRIGLIA CATEGORIE
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 100),
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
                  mode: widget.mode,
                  isTvSeries:
                      isTvSeries, // Ora passa il valore corretto dinamicamente
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
