import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/Pages/about_page.dart';
import 'package:library_ai/Pages/import_letterboxd_page.dart';
import 'package:library_ai/domain/use_cases/export_user_data_use_case.dart';
import '../../models/app_mode.dart';
import 'package:library_ai/l10n/app_localizations.dart';

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
        final authUser = snapshot.data;

        if (authUser == null) {
          return const SizedBox.shrink();
        }

        return FutureBuilder(
          future: sl<GetUserDataUseCase>().call(authUser.id),
          builder: (context, profileSnapshot) {
            final user = profileSnapshot.data ?? authUser;

            return Theme(
              data: Theme.of(context).copyWith(
                drawerTheme: const DrawerThemeData(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              ),
              child: Drawer(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(28),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      decoration: BoxDecoration(
                        // Pure black — same as home page backgroundColor
                        color: Colors.black,
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // ── Header card ─────────────────────────────────
                          SideMenuHeader(user: user),

                          // ── Nav list ────────────────────────────────────
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildSectionLabel(
                                  AppLocalizations.of(context)!.sideMenuExplore,
                                ),
                                const SizedBox(height: 6),

                                SideMenuItem(
                                  icon: Icons.movie_filter_rounded,
                                  text: AppLocalizations.of(context)!
                                      .sideMenuCinemaTv,
                                  isSelected: !isSocialActive,
                                  activeColor: _brandColor,
                                  onTap: () {
                                    onModeChanged(AppMode.movies);
                                    Navigator.pop(context);
                                  },
                                ),

                                const SizedBox(height: 24),
                                _buildDivider(),
                                const SizedBox(height: 24),

                                _buildSectionLabel(
                                  AppLocalizations.of(context)!
                                      .sideMenuCommunity,
                                ),
                                const SizedBox(height: 6),

                                SideMenuItem(
                                  icon: Icons.public_rounded,
                                  text: AppLocalizations.of(context)!
                                      .sideMenuSocial,
                                  isSelected: isSocialActive,
                                  activeColor: _brandColor,
                                  onTap: () {
                                    onSocialTap();
                                    Navigator.pop(context);
                                  },
                                ),

                                const SizedBox(height: 24),
                                _buildDivider(),
                                const SizedBox(height: 24),

                                _buildSectionLabel(
                                  AppLocalizations.of(context)!.sideMenuProject,
                                ),
                                const SizedBox(height: 6),

                                SideMenuItem(
                                  icon: Icons.info_outline_rounded,
                                  text: AppLocalizations.of(context)!
                                      .sideMenuInfoSupport,
                                  isSelected: false,
                                  activeColor: _brandColor,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AboutPage(),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 24),
                                _buildDivider(),
                                const SizedBox(height: 24),

                                _buildSectionLabel(
                                  AppLocalizations.of(context)!
                                      .sideMenuDataPortability,
                                ),
                                const SizedBox(height: 6),

                                SideMenuItem(
                                  icon: Icons.file_download_outlined,
                                  text: AppLocalizations.of(context)!
                                      .sideMenuImportLetterboxd,
                                  isSelected: false,
                                  activeColor: _brandColor,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ImportLetterboxdPage(),
                                      ),
                                    );
                                  },
                                ),

                                SideMenuItem(
                                  icon: Icons.upload_file_outlined,
                                  text: AppLocalizations.of(context)!
                                      .sideMenuExportData,
                                  isSelected: false,
                                  activeColor: _brandColor,
                                  onTap: () async {
                                    final currentUser =
                                        sl<AuthRepository>().currentUser;
                                    if (currentUser == null) return;

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.orangeAccent,
                                        ),
                                      ),
                                    );

                                    try {
                                      await sl<ExportUserDataUseCase>()
                                          .call(currentUser.id);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .exportDataSuccess,
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .exportDataError(
                                                    e.toString(),
                                                  ),
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          // ── Logout footer ────────────────────────────────
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 36),
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
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.08),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
