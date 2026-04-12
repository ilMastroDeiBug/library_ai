import 'dart:ui';
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
          data: Theme.of(context).copyWith(
            drawerTheme: const DrawerThemeData(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          child: Drawer(
            child: ClipRect(
              child: BackdropFilter(
                // FIX: Blur leggermente ridotto per far passare meglio i colori
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    // FIX: Opacità abbassata a 0.45 per un effetto molto più "vetro" e meno "muro"
                    color: Colors.black.withOpacity(0.45),
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withOpacity(
                          0.1,
                        ), // Leggermente più visibile per staccare dal fondo
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 1. HEADER
                      SideMenuHeader(user: user),

                      const SizedBox(height: 10),

                      // 2. LISTA MENU
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildSectionLabel("ESPLORA"),
                            const SizedBox(height: 10),

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
                            const SizedBox(height: 10),

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
                                horizontal: 10,
                              ),
                              child: Divider(
                                color: Colors.white.withOpacity(0.05),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // 3. FOOTER LOGOUT
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: LogoutButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
