import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../../models/app_mode.dart';
import '../../pages/settings_page.dart';
// Import Widget Modulari
import '../models/side_menu_widgets/side_menu_header.dart';
import '../models/side_menu_widgets/side_menu_item.dart';
import '../models/side_menu_widgets/logout_button.dart';

class SideMenu extends StatelessWidget {
  final AppMode currentMode;
  final bool isSocialActive;
  final Function(AppMode) onModeChanged;
  final VoidCallback onSocialTap;

  // IL COLORE DEL BRAND
  static const Color _brandColor = Colors.orangeAccent;

  const SideMenu({
    super.key,
    required this.currentMode,
    required this.isSocialActive,
    required this.onModeChanged,
    required this.onSocialTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
              ),
            ),
            child: Column(
              children: [
                // 1. HEADER
                SideMenuHeader(user: user),

                const SizedBox(height: 20),

                // 2. LISTA MENU
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildSectionLabel("ESPLORA"),

                      SideMenuItem(
                        icon: Icons.movie_filter_rounded,
                        text: "Cinema & TV",
                        isSelected:
                            !isSocialActive && currentMode == AppMode.movies,
                        activeColor: _brandColor, // Uniformato
                        onTap: () {
                          onModeChanged(AppMode.movies);
                          Navigator.pop(context);
                        },
                      ),

                      SideMenuItem(
                        icon: Icons.auto_stories_rounded,
                        text: "Libri",
                        isSelected:
                            !isSocialActive && currentMode == AppMode.books,
                        activeColor: _brandColor, // Uniformato
                        onTap: () {
                          onModeChanged(AppMode.books);
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 25),
                      _buildSectionLabel("COMMUNITY"),

                      SideMenuItem(
                        icon: Icons.public,
                        text: "Social Network",
                        isSelected: isSocialActive,
                        activeColor: _brandColor, // Uniformato
                        onTap: () {
                          onSocialTap();
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 25),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 25),

                      _buildSectionLabel("ALTRO"),

                      SideMenuItem(
                        icon: Icons.settings_rounded,
                        text: "Impostazioni",
                        isSelected: false,
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

                // 3. FOOTER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: LogoutButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Label uniformata al colore del brand
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: _brandColor.withOpacity(0.6), // Giallognolo trasparente
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
