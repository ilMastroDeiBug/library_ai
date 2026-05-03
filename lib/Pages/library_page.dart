import 'package:flutter/material.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/injection_container.dart';
import '../models/app_mode.dart';
import '../models/library_widgets/library_grid.dart';
import '../models/library_widgets/library_header.dart';

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

  String get _tab1Label => _isBooks ? "LETTI" : "VISTI";
  String get _tab2Label => _isBooks ? "DA LEGGERE" : "DA VEDERE";
  String get _tab3Label => "PREFERITI"; // <-- NUOVO TAB

  String get _status1 => _isBooks ? "read" : "watched";
  String get _status2 => _isBooks ? "toread" : "towatch";
  String get _status3 => "favorites"; // <-- NUOVO STATUS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: _isBooks ? _buildStyledFab() : null,
      body: StreamBuilder(
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
                length: 3, // <-- AGGIORNATO A 3
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
                      LibraryGrid(
                        mode: widget.mode,
                        status: _status3,
                      ), // <-- NUOVA GRID
                    ],
                  ),
                ),
              );
            },
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
              insets: EdgeInsets.symmetric(
                horizontal: 10,
              ), // <-- Ridotto per far spazio a 3 tab
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12, // <-- Leggermente ridotto
              letterSpacing: 1.0,
            ),
            tabs: [
              Tab(text: _tab1Label),
              Tab(text: _tab2Label),
              Tab(text: _tab3Label), // <-- NUOVO TAB
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
