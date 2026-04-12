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

  // FIX: Invertiti i label - I completati ora sono a sinistra (Tab 1)
  String get _tab1Label => _isBooks ? "LETTI" : "VISTI";
  String get _tab2Label => _isBooks ? "DA LEGGERE" : "DA VEDERE";

  // FIX: Invertiti gli stati - Il database caricherà i completati per il primo Tab
  String get _status1 => _isBooks ? "read" : "watched";
  String get _status2 => _isBooks ? "toread" : "towatch";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                  // Tab 1: Visti/Letti (Aperto di default)
                  LibraryGrid(mode: widget.mode, status: _status1),
                  // Tab 2: Da Vedere/Leggere
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
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: _brandColor, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 40),
            ),
            labelColor: Colors.white,
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
