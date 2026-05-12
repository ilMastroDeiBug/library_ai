import 'package:flutter/material.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/injection_container.dart';
import '../models/app_mode.dart';
import '../models/library_widgets/library_grid.dart';
import '../models/library_widgets/library_header.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class LibraryPage extends StatefulWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const LibraryPage({
    super.key,
    required this.mode,
    required this.onOpenDrawer,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool get _isBooks => widget.mode == AppMode.books;

  static const Color _brandColor = Colors.orangeAccent;

  String _tab1Label(BuildContext context) =>
      _isBooks ? AppLocalizations.of(context)!.libTabRead : AppLocalizations.of(context)!.watched;
  String _tab2Label(BuildContext context) =>
      _isBooks ? AppLocalizations.of(context)!.libTabReading : AppLocalizations.of(context)!.watching;
  String _tab3Label(BuildContext context) =>
      _isBooks ? AppLocalizations.of(context)!.libTabToRead : AppLocalizations.of(context)!.toWatch;
  String _tab4Label(BuildContext context) =>
      AppLocalizations.of(context)!.favorites;

  String get _status1 => _isBooks ? "read" : "watched";
  String get _status2 => _isBooks ? "reading" : "watching";
  String get _status3 => _isBooks ? "toread" : "towatch";
  String get _status4 => "favorites";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: _isBooks ? _buildStyledFab() : null,
      body: Stack(
        children: [
          // Sfondo Logo (solo watchlist o ovunque se preferito)
          if (!_isBooks)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2, // Più visibile e colorato
                child: Align(
                  alignment: const Alignment(
                    0,
                    0.5,
                  ), // Più in basso rispetto al centro
                  child: Image.asset(
                    'assets/images/logoCine.png',
                    width: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          StreamBuilder(
            stream: sl<AuthRepository>().userStream,
            builder: (context, snapshot) {
              final authUser = snapshot.data;
              if (authUser == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder(
                future: sl<GetUserDataUseCase>().call(authUser.id),
                builder: (context, profileSnapshot) {
                  final user = profileSnapshot.data ?? authUser;

                  return DefaultTabController(
                    length: 4, // <-- ORA SONO 4 TAB
                    child: NestedScrollView(
                      physics: const BouncingScrollPhysics(),
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [_buildSliverAppBar(user)];
                      },
                      body: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          LibraryGrid(mode: widget.mode, status: _status1),
                          LibraryGrid(mode: widget.mode, status: _status2),
                          LibraryGrid(mode: widget.mode, status: _status3),
                          LibraryGrid(mode: widget.mode, status: _status4),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(dynamic user) {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: LibraryHeader(
          mode: widget.mode,
          user: user,
          onOpenDrawer: widget.onOpenDrawer,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            isScrollable:
                true, // <-- Mettiamo true così ci stanno 4 tab senza stringersi
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: _brandColor, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
            tabs: [
              Tab(text: _tab1Label(context)),
              Tab(text: _tab2Label(context)),
              Tab(text: _tab3Label(context)),
              Tab(text: _tab4Label(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _brandColor.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'fab_library_main',
        backgroundColor: _brandColor,
        foregroundColor: Colors.black,
        elevation: 0,
        onPressed: () => _showComingSoon(context),
        child: const Icon(
          Icons.add_rounded,
          size: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.libManualInsertWip,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
