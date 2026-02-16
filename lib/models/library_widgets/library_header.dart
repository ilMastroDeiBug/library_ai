import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import '../../pages/settings_page.dart';
import '../app_mode.dart';
import 'library_stat_card.dart';

class LibraryHeader extends StatelessWidget {
  final AppMode mode;
  final AppUser? user;

  const LibraryHeader({super.key, required this.mode, required this.user});

  @override
  Widget build(BuildContext context) {
    // Utilizziamo l'arancione come colore unico del brand per coerenza
    const accentColor = Colors.orangeAccent;

    return Container(
      // Padding laterale standard per l'app
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profilo e Benvenuto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "BENTORNATO,",
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName?.toUpperCase() ?? "ARCHITECT",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildProfileAvatar(context, accentColor),
            ],
          ),

          const SizedBox(height: 30),

          // 2. Search Bar - Terminal Style
          _buildSearchBar(accentColor),

          const SizedBox(height: 30),

          // 3. Stats Row - In coda e Completati
          Row(
            children: [
              LibraryStatCard(
                label: mode == AppMode.books ? "DA LEGGERE" : "DA VEDERE",
                status: mode == AppMode.books ? "toread" : "towatch",
                icon: mode == AppMode.books
                    ? Icons.bookmark_outline
                    : Icons.movie_filter_outlined,
                accentColor: accentColor,
                mode: mode,
              ),
              const SizedBox(width: 16),
              LibraryStatCard(
                label: mode == AppMode.books ? "LETTI" : "VISTI",
                status: mode == AppMode.books ? "read" : "watched",
                icon: Icons.check_circle_outline,
                accentColor:
                    Colors.white, // Contrasto pulito per la seconda card
                mode: mode,
              ),
            ],
          ),

          // Spazio extra in fondo per non toccare la TabBar
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, Color accent) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      ),
      child: Hero(
        tag: 'profile_avatar_header',
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2A2A2A),
            child: Text(
              user?.displayName != null && user!.displayName!.isNotEmpty
                  ? user!.displayName![0].toUpperCase()
                  : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color accent) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Grigio molto scuro per l'input
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search, color: accent.withOpacity(0.6), size: 20),
          const SizedBox(width: 12),
          Text(
            "Cerca nel tuo archivio...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
