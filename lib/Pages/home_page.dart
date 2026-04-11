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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: widget.onOpenDrawer,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_rounded, color: _brandColor, size: 24),
          ),
        ),
      ),
      floatingActionButton: widget.mode == AppMode.books
          ? FloatingActionButton(
              heroTag: 'fab_home',
              onPressed: () => _showAddSheet(context),
              backgroundColor: _brandColor,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFF121212)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildSearchBar(context),

              // SWITCHER
              if (widget.mode == AppMode.movies)
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: HomeCinemaSwitcher(
                    selectedType: _selectedCinemaType,
                    onTypeChanged: (newType) {
                      _cinemaPageController.animateToPage(
                        newType == CinemaType.movies ? 0 : 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  ),
                ),

              // IL CUORE FLUIDO
              Expanded(
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
                          // Avvolgiamo l'intera pagina per mantenere lo scroll quando cambi tra Film e Serie TV
                          _KeepAliveSection(
                            child: _buildCinemaPage(CinemaType.movies),
                          ),
                          _KeepAliveSection(
                            child: _buildCinemaPage(CinemaType.tvSeries),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COSTRUZIONE LISTE OTTIMIZZATE ---

  // --- COSTRUZIONE LISTE OTTIMIZZATE ---

  Widget _buildCinemaPage(CinemaType type) {
    // 1. IL REGISTRO ANTI-CLONI: Si resetta ogni volta che cambi tab (Film/Serie)
    final Set<int> seenIds = {};

    // Passiamo il registro al costruttore dei contenuti
    final sections = HomeContentBuilder.buildCinemaContent(
      type: type,
      seenIds: seenIds,
    );

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _KeepAliveSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                HomeContentBuilder.buildHeroBanner(
                  widget.mode,
                  cinemaType: type,
                  seenIds: seenIds, // Passiamo il registro anche al Banner!
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: content.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _KeepAliveSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
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

  Widget _buildSearchBar(BuildContext context) {
    String placeholder = widget.mode == AppMode.books
        ? "Cerca titolo, autore..."
        : (_selectedCinemaType == CinemaType.movies
              ? "Cerca film..."
              : "Cerca serie TV...");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => showSearch(
          context: context,
          delegate: UniversalSearchDelegate(mode: widget.mode),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: _brandColor, size: 20),
              const SizedBox(width: 12),
              Text(
                placeholder,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- IL WIDGET MAGICO PER LA CACHE ---
// Questo widget dice a Flutter di non distruggere mai il suo contenuto
// quando esce dallo schermo. Perfetto per le chiamate API costose.
class _KeepAliveSection extends StatefulWidget {
  final Widget child;
  const _KeepAliveSection({required this.child});

  @override
  State<_KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<_KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  // Questa è la riga che fa la magia. True = non mi uccidere.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Fondamentale chiamare il super
    return widget.child;
  }
}
