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

const Color _kBrand = Colors.white;
const Color _kBg = Colors.black;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppUser? _currentUser;
  bool _isLoading = true;

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
            backgroundColor: Colors.white12,
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
      builder: (context) => _LanguagePickerSheet(
        langService: langService,
        onSelect: (code) async {
          await _updateLanguagePreference(code);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  String _getLanguageName(String code) =>
      code == 'it-IT' ? 'Italiano' : 'English';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white24,
            strokeWidth: 1.5,
          ),
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 0),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.pop(context)),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // ── Profile header (centered) ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
              child: SettingsHeader(
                user: _currentUser,
                bio: _currentUser?.bio ??
                    AppLocalizations.of(context)!.settingsNoBio,
                onPhotoTap: () {
                  if (_currentUser == null) return;
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => AvatarSelectionSheet(
                      userId: _currentUser!.id,
                      currentAvatarUrl: _currentUser?.photoUrl,
                      onAvatarUpdated: _loadData,
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Sections ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Esperienza ───────────────────────────────────────
                  _SectionLabel(
                    AppLocalizations.of(context)!.settingsExperience,
                  ),
                  SettingsTile(
                    icon: Icons.language_rounded,
                    title: AppLocalizations.of(context)!.settingsContentLanguage,
                    subtitle:
                        '${AppLocalizations.of(context)!.settingsCurrently} '
                        '${_getLanguageName(sl<LanguageService>().currentLanguage)}',
                    onTap: _showLanguagePicker,
                    isBottom: true,
                  ),

                  const SizedBox(height: 36),

                  // ── Account ──────────────────────────────────────────
                  _SectionLabel(
                    AppLocalizations.of(context)!.settingsAccountManagement,
                  ),
                  SettingsTile(
                    icon: Icons.badge_rounded,
                    title: AppLocalizations.of(context)!.settingsDisplayName,
                    subtitle: _currentUser?.displayName ??
                        AppLocalizations.of(context)!.settingsTapToSet,
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
                    onTap: () {
                      if (_currentUser == null) return;
                      EditProfileDialogs.showBioDialog(
                        context,
                        _currentUser?.bio ?? '',
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
                    iconColor: Colors.white38,
                    textColor: Colors.white.withValues(alpha: 0.80),
                    isBottom: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const DeleteAccountDialog(),
                      );
                    },
                  ),

                  const SizedBox(height: 52),

                  // ── Logout ───────────────────────────────────────────
                  Center(
                    child: _LogoutButton(
                      label: AppLocalizations.of(context)!.settingsLogout,
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
                    ),
                  ),

                  const SizedBox(height: 52),

                  // ── Watermark ─────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logoCine.png',
                          width: 22,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CineShare v1.0',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.12),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
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
    _scale = Tween<double>(begin: 1.0, end: 0.90).animate(
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Minimal uppercase section label — no boxes.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

/// Pill logout button — red text, white border.
class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _LogoutButton({required this.onTap, required this.label});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: 16,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language picker
// ─────────────────────────────────────────────────────────────────────────────
class _LanguagePickerSheet extends StatelessWidget {
  final LanguageService langService;
  final void Function(String code) onSelect;

  const _LanguagePickerSheet({
    required this.langService,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 44, top: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  AppLocalizations.of(context)!.settingsLanguageTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.settingsLanguageDesc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 28),
                _buildLangRow(context, 'Italiano', 'it-IT'),
                const SizedBox(height: 10),
                _buildLangRow(context, 'English', 'en-US'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangRow(BuildContext context, String title, String code) {
    final isSelected = langService.currentLanguage == code;
    final flag = code == 'it-IT' ? '\u{1F1EE}\u{1F1F9}' : '\u{1F1EC}\u{1F1E7}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => onSelect(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.60),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white.withValues(alpha: 0.80),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
