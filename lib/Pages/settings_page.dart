import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/services/utility_services/language_service.dart';

import '../models/settings_widgets/settings_header.dart';
import '../models/settings_widgets/settings_tile.dart';
import '../models/settings_widgets/edit_profile_dialogs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppUser? _currentUser;
  bool _isLoading = true;
  static const Color _brandColor = Colors.orangeAccent;

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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text(
            "LINGUA CONTENUTI",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.orangeAccent),
            title: const Text(
              "Italiano",
              style: TextStyle(color: Colors.white),
            ),
            trailing: langService.currentLanguage == 'it-IT'
                ? const Icon(Icons.check, color: _brandColor)
                : null,
            onTap: () {
              langService.updateLanguage('it-IT');
              Navigator.pop(context);
              setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blueAccent),
            title: const Text("English", style: TextStyle(color: Colors.white)),
            trailing: langService.currentLanguage == 'en-US'
                ? const Icon(Icons.check, color: _brandColor)
                : null,
            onTap: () {
              langService.updateLanguage('en-US');
              Navigator.pop(context);
              setState(() {});
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _getLanguageName(String code) =>
      code == 'it-IT' ? "Italiano" : "English";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: _brandColor)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "IMPOSTAZIONI",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader("PROFILO"),
          SettingsHeader(
            user: _currentUser, // Ora i tipi coincidono (AppUser)
            bio: _currentUser?.bio ?? "Nessuna biografia",
            onPhotoTap: () {},
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("PREFERENZE"),
          SettingsTile(
            icon: Icons.translate,
            title: "Lingua dei risultati",
            subtitle: _getLanguageName(sl<LanguageService>().currentLanguage),
            onTap: _showLanguagePicker,
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("MODIFICA DATI"),
          SettingsTile(
            icon: Icons.edit,
            title: "Nome Visualizzato",
            subtitle: _currentUser?.displayName ?? "Imposta nome",
            onTap: () => EditProfileDialogs.showNameDialog(
              context,
              _currentUser?.displayName,
              (name) => sl<UpdateProfileUseCase>()
                  .call(name)
                  .then((_) => _loadData()),
            ),
          ),
          SettingsTile(
            icon: Icons.text_snippet,
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
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () => sl<LogoutUseCase>().call().then(
                (_) => Navigator.pop(context),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("LOGOUT SESSIONE"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: _brandColor.withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
