import 'package:flutter/material.dart';
import '../services/utility_services/user_services.dart';
// Import Widget Modulari
import '/models/settings_widgets/settings_header.dart';
import '/models/settings_widgets/settings_tile.dart';
import '/models/settings_widgets/settings_switch_tile.dart';
import '/models/settings_widgets/edit_profile_dialogs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserService _userService = UserService();

  // Stato Locale (Solo UI)
  bool _isPublicProfile = true;
  bool _notificationsEnabled = false;
  String _bio = "Caricamento bio...";

  // COLORE DEL BRAND
  static const Color _brandColor = Colors.orangeAccent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _userService.getUserData();
    if (mounted && data != null) {
      setState(() {
        _bio = data['bio'] ?? "Nessuna biografia.";
        _isPublicProfile = data['isPublic'] ?? true;
      });
    }
  }

  Future<void> _handleUpdateName(String newName) async {
    await _userService.updateName(newName);
    setState(() {});
  }

  Future<void> _handleUpdateBio(String newBio) async {
    await _userService.updateBio(newBio);
    setState(() => _bio = newBio);
  }

  @override
  Widget build(BuildContext context) {
    final user = _userService.currentUser;

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

          // 1. HEADER
          SettingsHeader(
            user: user,
            bio: _bio,
            onPhotoTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Upload foto in arrivo con Firebase Storage!"),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 2. MODIFICA DATI
          _buildSectionHeader("MODIFICA DATI"),
          SettingsTile(
            icon: Icons.edit,
            title: "Nome Visualizzato",
            subtitle: user?.displayName ?? "Tocca per impostare",
            onTap: () => EditProfileDialogs.showNameDialog(
              context,
              user?.displayName,
              _handleUpdateName,
            ),
          ),
          SettingsTile(
            icon: Icons.text_snippet,
            title: "Biografia",
            subtitle: _bio.isEmpty ? "Raccontaci di te" : _bio,
            onTap: () => EditProfileDialogs.showBioDialog(
              context,
              _bio,
              _handleUpdateBio,
            ),
          ),
          SettingsTile(
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: user?.email ?? "Nessuna email",
            onTap: null, // Read-only
          ),

          const SizedBox(height: 20),

          // 3. PRIVACY & SICUREZZA
          _buildSectionHeader("PRIVACY & SICUREZZA"),
          SettingsSwitchTile(
            title: "Profilo Pubblico",
            subtitle: "Permetti agli altri di vedere la tua libreria",
            value: _isPublicProfile,
            onChanged: (val) async {
              setState(() => _isPublicProfile = val);
              await _userService.updatePrivacyProfile(val);
            },
          ),
          SettingsTile(
            icon: Icons.lock_reset,
            title: "Cambia Password",
            onTap: () async {
              try {
                await _userService.sendPasswordReset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "📧 Email per il reset inviata! Controlla la posta.",
                      ),
                      backgroundColor: Colors.green, // Verde per successo ok
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 20),

          // 4. PREFERENZE
          _buildSectionHeader("PREFERENZE APP"),
          SettingsSwitchTile(
            title: "Notifiche Push",
            subtitle: "Ricevi aggiornamenti e promemoria",
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          SettingsTile(
            icon: Icons.info_outline,
            title: "Informazioni App",
            subtitle: "Versione 1.0.0 Beta",
            onTap: () {},
          ),

          const SizedBox(height: 40),

          // 5. DANGER ZONE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Funzione critica non ancora implementata."),
                  ),
                );
              },
              child: const Text("ELIMINA ACCOUNT"),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // TITOLI SEZIONI (COLORE UNIFORMATO)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: _brandColor.withOpacity(0.8), // Giallognolo/Arancio
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
