import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/services/utility_services/language_service.dart';

import '../../main.dart';
import '../models/settings_widgets/settings_header.dart';
import '../models/settings_widgets/settings_tile.dart';
import '../models/settings_widgets/edit_profile_dialogs.dart';
import '../models/settings_widgets/delete_account_dialog.dart';
import '../models/settings_widgets/avatar_selection_sheet.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppUser? _currentUser;
  bool _isLoading = true;

  // PREMIUM PALETTE
  static const Color _brandColor = Colors.orangeAccent;
  static const Color _bgColor = Color(0xFF09090B); // Zinc-950 instead of pure black
  static const Color _surfaceColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authRepo = sl<AuthRepository>();
    final userAuth = await authRepo.userStream.first;

    if (userAuth != null) {
      try {
        final userData = await sl<GetUserDataUseCase>().call(userAuth.id);
        await sl<LanguageService>().syncLanguage(
          userData?.languagePreference ?? userAuth.languagePreference,
          notify: false,
        );
        if (mounted) {
          setState(() {
            _currentUser = userData ?? userAuth;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _currentUser = userAuth;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLanguagePreference(String code) async {
    final normalizedCode = code == 'en-US' ? 'en-US' : 'it-IT';
    final previousLanguage = sl<LanguageService>().currentLanguage;

    try {
      await sl<LanguageService>().updateLanguage(normalizedCode);

      if (_currentUser != null) {
        await sl<UpdateLanguagePreferenceUseCase>().call(
          _currentUser!.id,
          normalizedCode,
        );
      }

      if (mounted) {
        setState(() {
          if (_currentUser != null) {
            _currentUser = AppUser(
              id: _currentUser!.id,
              email: _currentUser!.email,
              displayName: _currentUser!.displayName,
              bio: _currentUser!.bio,
              photoUrl: _currentUser!.photoUrl,
              isPublic: _currentUser!.isPublic,
              languagePreference: normalizedCode,
            );
          }
        });
      }
    } catch (e) {
      await sl<LanguageService>().syncLanguage(previousLanguage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.settingsLanguageError}${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showLanguagePicker() {
    final langService = sl<LanguageService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161618).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40, top: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    AppLocalizations.of(context)!.settingsLanguageTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.settingsLanguageDesc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildLangOption(langService, "Italiano", "it-IT", '🇮🇹'),
                  const SizedBox(height: 12),
                  _buildLangOption(langService, "English", "en-US", '🇬🇧'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangOption(
    LanguageService service,
    String title,
    String code,
    String emoji,
  ) {
    final isSelected = service.currentLanguage == code;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _updateLanguagePreference(code);
            if (mounted) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? _brandColor.withOpacity(0.12)
                  : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _brandColor.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: _brandColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code) =>
      code == 'it-IT' ? "Italiano" : "English";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _brandColor)),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Subtle Glowing Orb - Less saturated, more blurred (Liquid Glass aesthetic)
          Positioned(
            top: -150,
            left: -100, // Asymmetric placement
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandColor.withOpacity(0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // No App Bar. Using SliverToBoxAdapter for a more editorial look
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        AppLocalizations.of(context)!.settingsProfileTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsHeader(
                        user: _currentUser,
                        bio:
                            _currentUser?.bio ??
                            AppLocalizations.of(context)!.settingsNoBio,
                        onPhotoTap: () {
                          if (_currentUser == null) return;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => AvatarSelectionSheet(
                              userId: _currentUser!.id,
                              currentAvatarUrl: _currentUser?.photoUrl,
                              onAvatarUpdated: () {
                                _loadData();
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      _buildSectionTitle(AppLocalizations.of(context)!.settingsExperience),
                      _buildSettingsGroup([
                        SettingsTile(
                          icon: Icons.language_rounded,
                          title: AppLocalizations.of(context)!.settingsContentLanguage,
                          subtitle:
                              "${AppLocalizations.of(context)!.settingsCurrently} ${_getLanguageName(sl<LanguageService>().currentLanguage)}",
                          onTap: _showLanguagePicker,
                          isBottom: true,
                          iconColor: Colors.blueAccent,
                        ),
                      ]),

                      const SizedBox(height: 40),

                      _buildSectionTitle(AppLocalizations.of(context)!.settingsAccountManagement),
                      _buildSettingsGroup([
                        SettingsTile(
                          icon: Icons.badge_rounded,
                          title: AppLocalizations.of(context)!.settingsDisplayName,
                          subtitle:
                              _currentUser?.displayName ??
                              AppLocalizations.of(context)!.settingsTapToSet,
                          iconColor: Colors.orangeAccent,
                          onTap: () {
                            if (_currentUser == null) return;
                            EditProfileDialogs.showNameDialog(
                              context,
                              _currentUser?.displayName,
                              (name) => sl<UpdateNameUseCase>()
                                  .call(_currentUser!.id, name)
                                  .then((_) => _loadData()),
                            );
                          },
                        ),
                        SettingsTile(
                          icon: Icons.format_quote_rounded,
                          title: AppLocalizations.of(context)!.settingsBio,
                          subtitle: AppLocalizations.of(context)!.settingsEditDesc,
                          iconColor: Colors.purpleAccent,
                          onTap: () {
                            if (_currentUser == null) return;
                            EditProfileDialogs.showBioDialog(
                              context,
                              _currentUser?.bio ?? "",
                              (bio) => sl<UpdateBioUseCase>()
                                  .call(_currentUser!.id, bio)
                                  .then((_) => _loadData()),
                            );
                          },
                        ),
                        SettingsTile(
                          icon: Icons.delete_outline_rounded,
                          title: AppLocalizations.of(context)!.settingsDeleteAccount,
                          subtitle: AppLocalizations.of(context)!.settingsDeleteAccountDesc,
                          iconColor: Colors.redAccent,
                          textColor: Colors.redAccent,
                          isBottom: true,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => const DeleteAccountDialog(),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 50),

                      // Magnetic Logout Button
                      Center(
                        child: _MagneticButton(
                          onTap: () async {
                            await sl<LogoutUseCase>().call();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthGate(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          label: AppLocalizations.of(context)!.settingsLogout,
                        ),
                      ),

                      const SizedBox(height: 40),

                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/logoCine.png',
                              width: 30,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "CineShare v1.0",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Purely typographic logic grouping, NO boxes
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  // Dashboard hardening: Data metrics breathe without being boxed
  Widget _buildSettingsGroup(List<Widget> children) {
    return Column(children: children);
  }
}

// ─── Magnetic Tactile Button ─────────────────────────────────────────────────
class _MagneticButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _MagneticButton({required this.onTap, required this.label});

  @override
  State<_MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<_MagneticButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.redAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.power_settings_new_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
