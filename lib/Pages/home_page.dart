import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '../models/home_widgets/home_content_builders.dart';
import '../models/home_widgets/home_cinema_switcher.dart';
import 'search_page.dart';

// --- IMPORT SOSPESI TEMPORANEAMENTE PER IL REFACTORING ---
// import '../models/book_widgets/add_book_sheet.dart';
// import '../models/user_books_section.dart';

class HomePage extends StatefulWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const HomePage({super.key, required this.mode, required this.onOpenDrawer});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _brandColor = Colors.orangeAccent;

  late PageController _cinemaPageController;
  CinemaType _selectedCinemaType = CinemaType.movies;

  @override
  void initState() {
    super.initState();
    _cinemaPageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _cinemaPageController.dispose();
    super.dispose();
  }

  /* SOSPESO: Tasto Aggiungi Libro
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
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // NERO ASSOLUTO
      // Il FAB dei libri è disattivato per il lancio MVP
      floatingActionButton: null,

      // LO STACK È IL SEGRETO PER L'EFFETTO TIKTOK
      body: Stack(
        children: [
          // LIVELLO 1: I CONTENUTI (Base)
          Positioned.fill(
            child: widget.mode == AppMode.books
                ? _buildComingSoonBooks(
                    context,
                  ) // <-- LEVA MARKETING: Sostituisce la vecchia UI
                : PageView(
                    controller: _cinemaPageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _selectedCinemaType = index == 0
                            ? CinemaType.movies
                            : CinemaType.tvSeries;
                      });
                    },
                    children: [
                      _KeepAliveSection(
                        child: _buildCinemaPage(CinemaType.movies),
                      ),
                      _KeepAliveSection(
                        child: _buildCinemaPage(CinemaType.tvSeries),
                      ),
                    ],
                  ),
          ),

          // LIVELLO 2: L'HEADER FLUTTUANTE (Top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildModernHeader(context),
          ),
        ],
      ),
    );
  }

  // --- IL NUOVO HEADER STILE TIKTOK ---
  Widget _buildModernHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 25,
        left: 20,
        right: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tasto Menu
          GestureDetector(
            onTap: widget.onOpenDrawer,
            child: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 28,
              shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
            ),
          ),

          // Switcher Centrale (O Titolo Libri)
          if (widget.mode == AppMode.movies)
            HomeCinemaSwitcher(
              selectedType: _selectedCinemaType,
              onTypeChanged: (newType) {
                _cinemaPageController.animateToPage(
                  newType == CinemaType.movies ? 0 : 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
            )
          else
            const Text(
              "La Biblioteca",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
              ),
            ),

          // Tasto Ricerca a scomparsa (Disabilitato nei libri per non innescare query)
          if (widget.mode == AppMode.movies)
            GestureDetector(
              onTap: () => showSearch(
                context: context,
                delegate: UniversalSearchDelegate(mode: widget.mode),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 28,
                shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
              ),
            )
          else
            const SizedBox(width: 28), // Spazio vuoto per bilanciare la Row
        ],
      ),
    );
  }

  // --- 🔒 LA LEVA MARKETING (Coming Soon Books) ---
  Widget _buildComingSoonBooks(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 80,
                color: Colors.white30,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Il Vault Definitivo",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Stiamo costruendo un ecosistema perfetto per i tuoi libri: dati curati, copertine in HD e analisi IA avanzate.\n\nNon scendiamo a compromessi sulla qualità. In arrivo nei prossimi aggiornamenti.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "🚀 Grazie! Ti avviseremo non appena il Vault dei libri sarà sbloccato.",
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF2C2C2C),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text(
                "Avvisami al rilascio",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                shadowColor: _brandColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COSTRUZIONE LISTE OTTIMIZZATE (CINEMA) ---
  Widget _buildCinemaPage(CinemaType type) {
    final Set<int> seenIds = {};
    final sections = HomeContentBuilder.buildCinemaContent(
      type: type,
      seenIds: seenIds,
    );

    return ListView.builder(
      padding: const EdgeInsets.only(top: 0, bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _KeepAliveSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeContentBuilder.buildHeroBanner(
                  widget.mode,
                  cinemaType: type,
                  seenIds: seenIds,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        }
        return _KeepAliveSection(child: sections[index - 1]);
      },
    );
  }

  /* SOSPESO: La vecchia UI dei libri
  Widget _buildStaticScroll(List<Widget> content) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 0, bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: content.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _KeepAliveSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeContentBuilder.buildHeroBanner(widget.mode),
                const SizedBox(height: 30),
                const UserBooksSection(
                  title: "In coda di lettura",
                  status: "toread",
                ),
              ],
            ),
          );
        }
        return _KeepAliveSection(child: content[index - 1]);
      },
    );
  }
  */
}

// --- IL WIDGET MAGICO PER LA CACHE ---
class _KeepAliveSection extends StatefulWidget {
  final Widget child;
  const _KeepAliveSection({required this.child});

  @override
  State<_KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<_KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
