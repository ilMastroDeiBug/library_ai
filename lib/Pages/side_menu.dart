import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/settings_page.dart';
import '../models/app_mode.dart'; // <--- Assicurati che questo file esista

class SideMenu extends StatelessWidget {
  // 1. I PARAMETRI CHE IL NAVIGATION HUB TI PASSA
  final AppMode currentMode;
  final bool isSocialActive;
  final Function(AppMode) onModeChanged;
  final VoidCallback onSocialTap;

  // 2. IL COSTRUTTORE CHE LI RICEVE
  const SideMenu({
    super.key,
    required this.currentMode,
    required this.isSocialActive,
    required this.onModeChanged,
    required this.onSocialTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E), // Grigio Menu
      child: Column(
        children: [
          // HEADER PROFILO (Settings Shortcut)
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C2C2C), Color(0xFF121212)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              accountName: Row(
                children: [
                  Text(
                    user?.displayName ?? "Architect",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.settings_outlined,
                    color: Colors.white38,
                    size: 14,
                  ),
                ],
              ),
              accountEmail: Text(
                user?.email ?? "",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),

          // SEZIONE CONTENUTI
          _buildSectionLabel("CONTENUTI"),

          _buildDrawerItem(
            context,
            icon: Icons.auto_stories,
            text: "Libreria Libri",
            // Logica colore: Attivo solo se NON social e MODO = libri
            color: (!isSocialActive && currentMode == AppMode.books)
                ? Colors.cyanAccent
                : Colors.white,
            onTap: () {
              onModeChanged(AppMode.books);
              Navigator.pop(context);
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.movie_filter_rounded,
            text: "Cinema & Serie TV",
            // Logica colore: Attivo solo se NON social e MODO = film
            color: (!isSocialActive && currentMode == AppMode.movies)
                ? Colors.orangeAccent
                : Colors.white,
            onTap: () {
              onModeChanged(AppMode.movies);
              Navigator.pop(context);
            },
          ),

          const SizedBox(height: 10),

          // SEZIONE SOCIAL
          _buildSectionLabel("COMMUNITY"),
          _buildDrawerItem(
            context,
            icon: Icons.people_alt_rounded,
            text: "Social Network",
            // Logica colore: Attivo se SOCIAL è true
            color: isSocialActive ? Colors.purpleAccent : Colors.white,
            onTap: () {
              onSocialTap();
              Navigator.pop(context); // Chiudiamo il drawer dopo il click
            },
          ),

          const Divider(color: Colors.white10, height: 40),

          // IMPOSTAZIONI
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            text: "Impostazioni",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),

          const Spacer(),

          // LOGOUT
          _buildDrawerItem(
            context,
            icon: Icons.logout_rounded,
            text: "Esci",
            color: Colors.redAccent.withOpacity(0.8),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: color != Colors.white
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      hoverColor: Colors.white.withOpacity(0.05),
    );
  }
}
