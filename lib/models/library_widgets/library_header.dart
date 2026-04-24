import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import '../../pages/settings_page.dart';
import '../app_mode.dart';

class LibraryHeader extends StatelessWidget {
  final AppMode mode;
  final AppUser? user;
  final VoidCallback onOpenDrawer;

  const LibraryHeader({
    super.key,
    required this.mode,
    required this.user,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Colors.orangeAccent;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MENU E PROFILO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onOpenDrawer,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              _buildProfileAvatar(context, accentColor),
            ],
          ),

          const Spacer(),

          // 2. TITOLO GIGANTE
          Text(
            mode == AppMode.books ? "Il tuo\nVault" : "La tua\nWatchlist",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -1.5,
            ),
          ),

          // FIX: Aumentato a 70 per spingere il titolo più in alto ed evitare coperture
          const SizedBox(height: 70),
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
                color: accent.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1E1E1E),
            // LOGICA AVATAR AGGIORNATA
            child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user!.photoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    user?.displayName != null && user!.displayName!.isNotEmpty
                        ? user!.displayName![0].toUpperCase()
                        : 'U', // 'U' per Utente se non ha ancora il nome
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
