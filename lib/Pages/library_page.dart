import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../models/app_mode.dart';
import '../models/library_widgets/library_header.dart';
import '../models/library_widgets/library_grid.dart';

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

  String get _tab1Label => _isBooks ? "DA LEGGERE" : "DA VEDERE";
  String get _tab2Label => _isBooks ? "LETTI" : "VISTI";

  String get _status1 => _isBooks ? "toread" : "towatch";
  String get _status2 => _isBooks ? "read" : "watched";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: _isBooks ? _buildStyledFab() : null,
      body: StreamBuilder(
        stream: sl<AuthRepository>().userStream,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return DefaultTabController(
            length: 2,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(dynamic user) {
    const double appBarHeight = 400.0;

    return SliverAppBar(
      expandedHeight: appBarHeight,
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      automaticallyImplyLeading:
          false, // Rimuove il leading di default per controllo totale
      // leading: Usiamo un allineamento diretto invece del Padding per centrare l'icona
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Sfondo sfumato
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _brandColor.withOpacity(0.08),
                    const Color(0xFF121212),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),

            // Header: spostato leggermente più in alto (da 80 a 70) per equilibrio visivo
            Padding(
              padding: const EdgeInsets.only(top: 75),
              child: LibraryHeader(mode: widget.mode, user: user),
            ),

            // Tasto Menu personalizzato posizionato manualmente per precisione millimetrica
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 15,
              child: GestureDetector(
                onTap: widget.onOpenDrawer,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  // Center garantisce che l'icona sia al centro del cerchio
                  child: const Center(
                    child: Icon(
                      Icons.menu_rounded,
                      color: _brandColor,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            border: Border(
              bottom: BorderSide(color: _brandColor.withOpacity(0.2), width: 1),
            ),
          ),
          child: TabBar(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            indicatorColor: _brandColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: _brandColor,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
            tabs: [
              Tab(text: _tab1Label),
              Tab(text: _tab2Label),
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
        content: const Text(
          "Inserimento manuale in fase di sviluppo.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
