import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '../models/book_widgets/add_book_sheet.dart';
import '../models/user_books_section.dart';
import '../models/home_widgets/home_content_builders.dart';
import '../models/home_widgets/home_cinema_switcher.dart';
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
      backgroundColor: Colors.black, // NERO ASSOLUTO
      // Niente AppBar statica! La UI si estende fino in cima.
      floatingActionButton: widget.mode == AppMode.books
          ? FloatingActionButton(
              heroTag: 'fab_home',
              onPressed: () => _showAddSheet(context),
              backgroundColor: _brandColor,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,

      // LO STACK È IL SEGRETO PER L'EFFETTO TIKTOK
      body: Stack(
        children: [
          // LIVELLO 1: I CONTENUTI (Base)
          Positioned.fill(
            child: widget.mode == AppMode.books
                ? _buildStaticScroll(HomeContentBuilder.buildBookContent())
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
      // Sfumatura nera verso il basso per rendere le icone sempre leggibili
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
      // Padding dinamico: rispetta il Notch/Isola dinamica dell'iPhone
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
              "Il tuo Vault",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
              ),
            ),

          // Tasto Ricerca a scomparsa
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
          ),
        ],
      ),
    );
  }

  // --- COSTRUZIONE LISTE OTTIMIZZATE ---

  Widget _buildCinemaPage(CinemaType type) {
    final Set<int> seenIds = {};
    final sections = HomeContentBuilder.buildCinemaContent(
      type: type,
      seenIds: seenIds,
    );

    return ListView.builder(
      // ATTENZIONE: top: 0 è fondamentale per il Full-Bleed!
      padding: const EdgeInsets.only(top: 0, bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _KeepAliveSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tolto il SizedBox superiore, il banner attacca il tetto!
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
