import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_mode.dart';
// Import Widget Modulari
import '../models/library_widgets/library_header.dart';
import '../models/library_widgets/library_grid.dart';

class LibraryPage extends StatelessWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const LibraryPage({
    super.key,
    required this.mode,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final isBooks = mode == AppMode.books;
    // Recuperiamo l'utente direttamente da Firebase (o tramite AuthRepository se preferisci)
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      floatingActionButton: isBooks ? _buildFab(context) : null,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 350,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0F0F10),
                leading: IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onOpenDrawer,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  // Passiamo l'utente all'header
                  background: LibraryHeader(mode: mode, user: user),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F10),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: TabBar(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      indicatorColor: Colors.white,
                      indicatorWeight: 2,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                      tabs: [
                        const Tab(text: "DA LEGGERE"),
                        Tab(text: isBooks ? "COMPLETATI" : "VISTI"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              LibraryGrid(mode: mode, status: "toread"),
              LibraryGrid(mode: mode, status: "read"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'fab_library',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Usa il tasto + nella Home per aggiungere libri!"),
            ),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
