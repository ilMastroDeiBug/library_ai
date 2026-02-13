import 'package:flutter/material.dart';
// CLEAN ARCH IMPORTS
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
// IMPORT CHE MANCAVA:
import 'package:library_ai/domain/repositories/auth_repository.dart';

// Import Widget Modulari
import '../models/settings_widgets/settings_header.dart';
import '../models/settings_widgets/settings_tile.dart';
//import '../models/settings_widgets/settings_switch_tile.dart';
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
    // 1. Otteniamo l'istanza del repository
    final authRepo = sl<AuthRepository>();

    // 2. Prendiamo l'utente corrente dallo stream
    final userAuth = await authRepo.userStream.first;

    if (userAuth != null) {
      try {
        // 3. Carichiamo i dati estesi dal DB
        final userData = await sl<GetUserDataUseCase>().call(userAuth.id);

        if (mounted) {
          setState(() {
            // Usa i dati completi se ci sono, altrimenti quelli base
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

  Future<void> _handleUpdateName(String newName) async {
    await sl<UpdateProfileUseCase>().call(newName);
    _loadData(); // Ricarica
  }

  Future<void> _handleUpdateBio(String newBio) async {
    if (_currentUser == null) return;
    await sl<UpdateBioUseCase>().call(_currentUser!.id, newBio);
    setState(() {
      _currentUser = AppUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: _currentUser!.displayName,
        bio: newBio,
        isPublic: _currentUser!.isPublic,
      );
    });
  }

  Future<void> _handleLogout() async {
    await sl<LogoutUseCase>().call();
    if (mounted) Navigator.pop(context);
  }

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
        title: const Text(
          "Impostazioni",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader("PROFILO"),
          // SettingsHeader deve accettare AppUser o i singoli campi
          SettingsHeader(
            user: null,
            bio: _currentUser?.bio ?? "Nessuna biografia",
            onPhotoTap: () {},
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
              _handleUpdateName,
            ),
          ),
          SettingsTile(
            icon: Icons.text_snippet,
            title: "Biografia",
            subtitle: _currentUser?.bio ?? "Raccontaci di te",
            onTap: () => EditProfileDialogs.showBioDialog(
              context,
              _currentUser?.bio ?? "",
              _handleUpdateBio,
            ),
          ),

          // ... altri tile ...
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
              ),
              onPressed: _handleLogout,
              child: const Text("LOGOUT"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: _brandColor.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
