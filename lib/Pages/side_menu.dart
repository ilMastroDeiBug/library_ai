import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/settings_page.dart';
import '../models/app_mode.dart';

class SideMenu extends StatelessWidget {
  final AppMode currentMode;
  final bool isSocialActive;
  final Function(AppMode) onModeChanged;
  final VoidCallback onSocialTap;

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

    // Colori principali
    const bgStart = Color(0xFF1E1E1E);
    const bgEnd = Color(0xFF0F0F0F);

    return Drawer(
      // Sfondo con Gradiente Sottile
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: Column(
          children: [
            // 1. HEADER PERSONALIZZATO
            _buildCustomHeader(context, user),

            const SizedBox(height: 20),

            // 2. LISTA MENU (Scrollabile)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildSectionLabel("ESPLORA"),

                  _buildMenuItem(
                    context,
                    icon: Icons.auto_stories_rounded,
                    text: "Libreria Libri",
                    isSelected: !isSocialActive && currentMode == AppMode.books,
                    activeColor: Colors.cyanAccent,
                    onTap: () {
                      onModeChanged(AppMode.books);
                      Navigator.pop(context);
                    },
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.movie_filter_rounded,
                    text: "Cinema & TV",
                    isSelected:
                        !isSocialActive && currentMode == AppMode.movies,
                    activeColor: Colors.orangeAccent,
                    onTap: () {
                      onModeChanged(AppMode.movies);
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 25),
                  _buildSectionLabel("COMMUNITY"),

                  _buildMenuItem(
                    context,
                    icon: Icons.public,
                    text: "Social Network",
                    isSelected: isSocialActive,
                    activeColor: Colors.purpleAccent,
                    onTap: () {
                      onSocialTap();
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 25),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 25),

                  _buildSectionLabel("ALTRO"),

                  _buildMenuItem(
                    context,
                    icon: Icons.settings_rounded,
                    text: "Impostazioni",
                    isSelected:
                        false, // Le impostazioni non sono una "modalità" persistente
                    activeColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 3. FOOTER (LOGOUT)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HEADER CUSTOM ---
  Widget _buildCustomHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
        child: Row(
          children: [
            // Avatar con Glow Effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2C2C2C),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(width: 15),
            // Testi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? "Architect",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Icona freccia discreta
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET LABEL SEZIONE ---
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // --- WIDGET MENU ITEM (STILE CAPSULA) ---
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: activeColor.withOpacity(0.3))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : Colors.white54,
                  size: 22,
                ),
                const SizedBox(width: 15),
                Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TASTO LOGOUT ---
  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text(
              "Disconnetti",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
