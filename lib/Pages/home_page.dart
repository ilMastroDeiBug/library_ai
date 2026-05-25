import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '../models/home_widgets/home_content_builders.dart';
import '../models/home_widgets/home_cinema_switcher.dart';
import '../models/home_widgets/home_tv_progress_section.dart'; // IMPORT AGGIUNTO
import 'search_page.dart';
import '../injection_container.dart';
import '../services/utility_services/language_service.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;
  // Nuovo parametro per intercettare il doppio click sulla bottom bar
  final ValueNotifier<int>? reselectNotifier;

  const HomePage({
    super.key,
    required this.mode,
    required this.onOpenDrawer,
    this.reselectNotifier,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _brandColor = Colors.orangeAccent;
  late PageController _cinemaPageController;
  CinemaType _selectedCinemaType = CinemaType.movies;

  // Controller per scrollare in cima e chiave per forzare il refresh
  final ScrollController _movieScrollController = ScrollController();
  final ScrollController _tvScrollController = ScrollController();
  Key _refreshKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _cinemaPageController = PageController(initialPage: 0);
    widget.reselectNotifier?.addListener(_onReselect);
  }

  @override
  void dispose() {
    widget.reselectNotifier?.removeListener(_onReselect);
    _cinemaPageController.dispose();
    _movieScrollController.dispose();
    _tvScrollController.dispose();
    super.dispose();
  }

  void _onReselect() {
    if (!mounted) return;

    final activeController = _selectedCinemaType == CinemaType.movies
        ? _movieScrollController
        : _tvScrollController;

    if (activeController.hasClients) {
      activeController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    _forceRefresh();
  }

  Future<void> _forceRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<LanguageService>(),
      builder: (context, _) {
        final languageCode = sl<LanguageService>().currentLanguage;

        return Scaffold(
          backgroundColor: Colors.black,
          floatingActionButton: null,
          body: Stack(
            children: [
              Positioned.fill(
                child: widget.mode == AppMode.books
                    ? _buildComingSoonBooks(context)
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
                            key: ValueKey('home_movies_$languageCode'),
                            child: _buildCinemaPage(
                              CinemaType.movies,
                              _movieScrollController,
                            ),
                          ),
                          _KeepAliveSection(
                            key: ValueKey('home_tv_$languageCode'),
                            child: _buildCinemaPage(
                              CinemaType.tvSeries,
                              _tvScrollController,
                            ),
                          ),
                        ],
                      ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
              child: _buildModernHeader(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPad + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.30),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
      child: Row(
        children: [
          // ── Menu ────────────────────────────────────────────────────────
          _HeaderIconButton(
            icon: Icons.menu_rounded,
            onTap: widget.onOpenDrawer,
          ),
          const Spacer(),

          // ── Switcher centrato ──────────────────────────────────────────
          if (widget.mode == AppMode.movies)
            HomeCinemaSwitcher(
              selectedType: _selectedCinemaType,
              onTypeChanged: (newType) {
                setState(() => _selectedCinemaType = newType);
                _cinemaPageController.animateToPage(
                  newType == CinemaType.movies ? 0 : 1,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              },
            )
          else
            Text(
              AppLocalizations.of(context)!.homeLibrary,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),

          const Spacer(),

          // ── Search ─────────────────────────────────────────────────────
          if (widget.mode == AppMode.movies)
            _HeaderIconButton(
              icon: Icons.search_rounded,
              onTap: () => showSearch(
                context: context,
                delegate: UniversalSearchDelegate(mode: widget.mode),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

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
            Text(
              AppLocalizations.of(context)!.homeVaultTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              AppLocalizations.of(context)!.homeVaultDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.homeVaultNotifyMsg,
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF2C2C2C),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_rounded),
              label: Text(
                AppLocalizations.of(context)!.homeNotifyMe,
                style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildCinemaPage(CinemaType type, ScrollController controller) {
    final Set<int> seenIds = {};
    final sections = HomeContentBuilder.buildCinemaContent(
      context,
      type: type,
      seenIds: seenIds,
    );

    return RefreshIndicator(
      color: _brandColor,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: _forceRefresh,
      child: ListView.builder(
        key: _refreshKey,
        controller: controller,
        padding: const EdgeInsets.only(top: 0, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _KeepAliveSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 60),
                  HomeContentBuilder.buildHeroBanner(
                    widget.mode,
                    cinemaType: type,
                    seenIds: seenIds,
                  ),
                  const SizedBox(height: 4),
                  // INIEZIONE DELLA SEZIONE STREAK "STAI GUARDANDO" SOTTO AL BANNER!
                  if (type == CinemaType.tvSeries)
                    const HomeTvProgressSection(),
                ],
              ),
            );
          }
          return _KeepAliveSection(child: sections[index - 1]);
        },
      ),
    );
  }
}

class _KeepAliveSection extends StatefulWidget {
  final Widget child;
  const _KeepAliveSection({super.key, required this.child});

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

// ─── Header icon button ───────────────────────────────────────────────────────
// Bottone icona 40×40 con feedback tattile — niente glow, solo scala al tocco.

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
