import 'package:flutter/material.dart';
import '../../models/app_mode.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/explore_use_cases.dart';
import '../models/category_card.dart';
import '../models/home_widgets/home_cinema_switcher.dart';
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

  // STATO LOCALE: Ricorda se stiamo guardando Film o Serie TV
  CinemaType _selectedCinemaType = CinemaType.movies;

  // Getter per comodità
  bool get isTvSeries => _selectedCinemaType == CinemaType.tvSeries;

  String _getTitle() {
    if (widget.mode == AppMode.books) return "Esplora\nLibri";
    return isTvSeries ? "Esplora\nSerie TV" : "Esplora\nCinema";
  }

  @override
  Widget build(BuildContext context) {
    // Caricamento categorie in tempo reale dal Service Locator
    final categories = sl<GetExploreCategoriesUseCase>().call(
      widget.mode,
      isTvSeries: isTvSeries,
    );

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black, // NERO ASSOLUTO STILE CINESHARE
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER IMMERSIVO (Senza l'orribile SliverAppBar statica)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. MENU E ICONA SEZIONE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tasto Menu Glassmorphism coerente col resto dell'app
                      GestureDetector(
                        onTap: widget.onOpenDrawer,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Icona decorativa
                      Icon(
                        widget.mode == AppMode.books
                            ? Icons.auto_stories_rounded
                            : Icons.movie_filter_rounded,
                        color: _brandColor.withOpacity(0.4),
                        size: 32,
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // 2. TITOLO GIGANTE
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. BARRA DI RICERCA (Vetro Semitrasparente)
                  GestureDetector(
                    onTap: () => showSearch(
                      context: context,
                      delegate: UniversalSearchDelegate(mode: widget.mode),
                    ),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Cerca un titolo, regista o autore...",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 4. SWITCHER FILM/SERIE TV (Allineato a sinistra)
                  if (widget.mode == AppMode.movies)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: HomeCinemaSwitcher(
                        selectedType: _selectedCinemaType,
                        onTypeChanged: (newType) {
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
            // Padding bottom a 120 per non far coprire le ultime card dalla barra di navigazione fluttuante
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio:
                    1.3, // Proporzione leggermente più "wide" e moderna
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => CategoryCard(
                  category: categories[index],
                  mode: widget.mode,
                  isTvSeries: isTvSeries,
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
