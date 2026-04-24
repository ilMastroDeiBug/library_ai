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
// IMPORT DEL NUOVO POPUP DEGLI AVATAR
import '../models/settings_widgets/avatar_selection_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppUser? _currentUser;
  bool _isLoading = true;
  static const Color _brandColor = Colors.orangeAccent;
  static const Color _bgColor = Color(0xFF0A0A0C);
  static const Color _surfaceColor = Color(0xFF161618);

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
        if (mounted) {
          setState(() {
            _currentUser = userData ?? userAuth;
            _isLoading =
                false; // Questo ricaricherà il widget SettingsHeader all'istante
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

  void _showLanguagePicker() {
    final langService = sl<LanguageService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _surfaceColor.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  const Text(
                    "SELEZIONA LINGUA",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Applica a interfaccia e risultati di ricerca",
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
          onTap: () {
            service.updateLanguage(code);
            Navigator.pop(context);
            setState(() {});
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? _brandColor.withOpacity(0.15)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _brandColor.withOpacity(0.5)
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
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 16,
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

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brandColor.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                centerTitle: true,
                expandedHeight: 80,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  centerTitle: true,
                  title: Text(
                    "IL MIO PROFILO",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
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
                            "Nessuna biografia impostata. Racconta chi sei.",
                        onPhotoTap: () {
                          // Lancia il popup di selezione avatar integrato
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => AvatarSelectionSheet(
                              userId: _currentUser!.id,
                              currentAvatarUrl: _currentUser?.photoUrl,
                              onAvatarUpdated: () {
                                _loadData(); // Ricarica la UI quando l'avatar viene salvato
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      _buildSectionTitle("ESPERIENZA", Icons.tune_rounded),
                      _buildSettingsGroup([
                        SettingsTile(
                          icon: Icons.translate_rounded,
                          title: "Lingua Contenuti",
                          subtitle:
                              "Attualmente ${_getLanguageName(sl<LanguageService>().currentLanguage)}",
                          onTap: _showLanguagePicker,
                          isTop: true,
                          isBottom: true,
                          iconColor: Colors.blueAccent,
                        ),
                      ]),

                      const SizedBox(height: 30),

                      _buildSectionTitle(
                        "GESTIONE ACCOUNT",
                        Icons.manage_accounts_rounded,
                      ),
                      _buildSettingsGroup([
                        SettingsTile(
                          icon: Icons.badge_rounded,
                          title: "Nome Visualizzato",
                          subtitle:
                              _currentUser?.displayName ??
                              "Tocca per impostare",
                          isTop: true,
                          iconColor: Colors.greenAccent,
                          onTap: () => EditProfileDialogs.showNameDialog(
                            context,
                            _currentUser?.displayName,
                            (name) => sl<UpdateProfileUseCase>()
                                .call(name)
                                .then((_) => _loadData()),
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.format_quote_rounded,
                          title: "Biografia",
                          subtitle: "Modifica la tua descrizione",
                          iconColor: Colors.purpleAccent,
                          onTap: () => EditProfileDialogs.showBioDialog(
                            context,
                            _currentUser?.bio ?? "",
                            (bio) => sl<UpdateBioUseCase>()
                                .call(_currentUser!.id, bio)
                                .then((_) => _loadData()),
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.delete_outline_rounded,
                          title: "Elimina Account",
                          subtitle: "Rimuovi permanentemente i dati",
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

                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 18,
                            ),
                            side: BorderSide(
                              color: Colors.redAccent.withOpacity(0.5),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.redAccent.withOpacity(0.05),
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                          ),
                          onPressed: () async {
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
                          icon: const Icon(
                            Icons.power_settings_new_rounded,
                            size: 22,
                          ),
                          label: const Text(
                            "DISCONNETTI",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/logoCine.png', // Stesso nome indicato nel codice originale
                              width: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "CineShare v1.0",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.4), size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
