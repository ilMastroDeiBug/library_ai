import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../../models/app_mode.dart';
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

        return Theme(
          // Rimuoviamo lo sfondo bianco predefinito del Drawer
          data: Theme.of(context).copyWith(
            drawerTheme: const DrawerThemeData(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          child: Drawer(
            child: Row(
              children: [
                // Il contenitore principale arrotondato
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0C), // Sfondo profondissimo
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 1. HEADER (Card Profilo)
                          SideMenuHeader(user: user),

                          // 2. LISTA MENU
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildSectionLabel("ESPLORA"),
                                const SizedBox(height: 8),

                                SideMenuItem(
                                  icon: Icons.movie_filter_rounded,
                                  text: "Cinema & TV",
                                  isSelected:
                                      !isSocialActive &&
                                      currentMode == AppMode.movies,
                                  activeColor: _brandColor,
                                  onTap: () {
                                    onModeChanged(AppMode.movies);
                                    Navigator.pop(context);
                                  },
                                ),

                                SideMenuItem(
                                  icon: Icons.auto_stories_rounded,
                                  text: "Vault Libri",
                                  isSelected:
                                      !isSocialActive &&
                                      currentMode == AppMode.books,
                                  activeColor: _brandColor,
                                  onTap: () {
                                    onModeChanged(AppMode.books);
                                    Navigator.pop(context);
                                  },
                                ),

                                const SizedBox(height: 30),
                                _buildSectionLabel("COMMUNITY"),
                                const SizedBox(height: 8),

                                SideMenuItem(
                                  icon: Icons.public_rounded,
                                  text: "CineShare Social",
                                  isSelected: isSocialActive,
                                  activeColor: _brandColor,
                                  onTap: () {
                                    onSocialTap();
                                    Navigator.pop(context);
                                  },
                                ),

                                const SizedBox(height: 30),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Divider(
                                    color: Colors.white.withOpacity(0.05),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                _buildSectionLabel("SISTEMA"),
                                const SizedBox(height: 8),

                                SideMenuItem(
                                  icon: Icons.settings_rounded,
                                  text: "Impostazioni",
                                  isSelected: false,
                                  activeColor: Colors.white,
                                  onTap: () {
                                    // Navigator.pop(context); -> rimettere quando la pagina esiste
                                  },
                                ),
                              ],
                            ),
                          ),

                          // 3. FOOTER LOGOUT
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 40),
                            child: LogoutButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Uno spazietto trasparente a destra per far vedere lo sfondo dell'app
                const SizedBox(width: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
