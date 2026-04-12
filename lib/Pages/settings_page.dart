import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/services/utility_services/language_service.dart';

import '../../main.dart'; // <-- IMPORT AGGIUNTO PER AUTHGATE
import '../models/settings_widgets/settings_header.dart';
import '../models/settings_widgets/settings_tile.dart';
import '../models/settings_widgets/edit_profile_dialogs.dart';
import '../models/settings_widgets/delete_account_dialog.dart';

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

  void _showLanguagePicker() {
    final langService = sl<LanguageService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pillola superiore per lo swipe
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "LINGUA APP",
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            _buildLangOption(langService, "Italiano", "it-IT", Icons.flag),
            _buildLangOption(langService, "English", "en-US", Icons.public),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(
    LanguageService service,
    String title,
    String code,
    IconData icon,
  ) {
    final isSelected = service.currentLanguage == code;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? _brandColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? _brandColor : Colors.white54,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: _brandColor)
          : null,
      onTap: () {
        service.updateLanguage(code);
        Navigator.pop(context);
        setState(() {});
      },
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "IMPOSTAZIONI",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: _surfaceColor,
              shape: BoxShape.circle,
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          SettingsHeader(
            user: _currentUser,
            bio: _currentUser?.bio ?? "Nessuna biografia",
            onPhotoTap: () {},
          ),
          const SizedBox(height: 30),

          _buildSectionTitle("PREFERENZE"),
          _buildSettingsGroup([
            SettingsTile(
              icon: Icons.translate_rounded,
              title: "Lingua dei risultati",
              subtitle: _getLanguageName(sl<LanguageService>().currentLanguage),
              onTap: _showLanguagePicker,
              isTop: true,
              isBottom: true,
            ),
          ]),

          const SizedBox(height: 25),
          _buildSectionTitle("ACCOUNT"),
          _buildSettingsGroup([
            SettingsTile(
              icon: Icons.badge_rounded,
              title: "Nome Visualizzato",
              subtitle: _currentUser?.displayName ?? "Imposta nome",
              isTop: true,
              onTap: () => EditProfileDialogs.showNameDialog(
                context,
                _currentUser?.displayName,
                (name) => sl<UpdateProfileUseCase>()
                    .call(name)
                    .then((_) => _loadData()),
              ),
            ),
            SettingsTile(
              icon: Icons.text_snippet_rounded,
              title: "Biografia",
              subtitle: _currentUser?.bio ?? "Raccontaci di te",
              onTap: () => EditProfileDialogs.showBioDialog(
                context,
                _currentUser?.bio ?? "",
                (bio) => sl<UpdateBioUseCase>()
                    .call(_currentUser!.id, bio)
                    .then((_) => _loadData()),
              ),
            ),
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              title: "Elimina Account",
              subtitle: "Azione irreversibile",
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

          const SizedBox(height: 40),

          // Tasto Logout Premium AGGIORNATO
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: Colors.redAccent.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              foregroundColor: Colors.redAccent,
            ),
            // FIX LOGICA: Resetta la navigazione e rimette in gioco AuthGate
            onPressed: () async {
              await sl<LogoutUseCase>().call();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.power_settings_new_rounded),
            label: const Text(
              "DISCONNETTI",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }
}
