import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Solo per currentUser (temporaneo) o meglio usare AuthRepository
// CLEAN ARCH IMPORTS
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart'; // Per UpdateName, ResetPassword
import 'package:library_ai/domain/use_cases/user_cases.dart'; // CREIAMOLI SOTTO: UpdateBio, GetUserData, UpdatePrivacy

// Import Widget Modulari
import '../models/settings_widgets/settings_header.dart';
import '../models/settings_widgets/settings_tile.dart';
import '../models/settings_widgets/settings_switch_tile.dart';
import '../models/settings_widgets/edit_profile_dialogs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Stato Locale
  bool _isPublicProfile = true;
  bool _notificationsEnabled = false;
  String _bio = "Caricamento bio...";

  // Otteniamo l'utente corrente da FirebaseAuth per ID/Email (Pragmatismo)
  // In futuro potresti aggiungerlo all'AuthRepository
  final User? currentUser = FirebaseAuth.instance.currentUser;

  static const Color _brandColor = Colors.orangeAccent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (currentUser == null) return;
    try {
      // USE CASE: GetUserData
      final userEntity = await sl<GetUserDataUseCase>().call(currentUser!.uid);
      if (mounted && userEntity != null) {
        setState(() {
          _bio = userEntity.bio ?? "Nessuna biografia.";
          // _isPublicProfile = userEntity.isPublic; // Se aggiungi questo campo all'Entity
        });
      }
    } catch (e) {
      if (mounted) setState(() => _bio = "Errore caricamento.");
    }
  }

  Future<void> _handleUpdateName(String newName) async {
    await sl<UpdateProfileUseCase>().call(newName);
    setState(() {}); // Ricarica UI
  }

  Future<void> _handleUpdateBio(String newBio) async {
    if (currentUser == null) return;
    await sl<UpdateBioUseCase>().call(currentUser!.uid, newBio);
    setState(() => _bio = newBio);
  }

  @override
  Widget build(BuildContext context) {
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
          SettingsHeader(
            user:
                currentUser, // Passiamo l'User di Firebase al widget header (compatibilità)
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

          _buildSectionHeader("MODIFICA DATI"),
          SettingsTile(
            icon: Icons.edit,
            title: "Nome Visualizzato",
            subtitle: currentUser?.displayName ?? "Tocca per impostare",
            onTap: () => EditProfileDialogs.showNameDialog(
              context,
              currentUser?.displayName,
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
            subtitle: currentUser?.email ?? "Nessuna email",
            onTap: null,
          ),

          const SizedBox(height: 20),

          _buildSectionHeader("PRIVACY & SICUREZZA"),
          SettingsSwitchTile(
            title: "Profilo Pubblico",
            subtitle: "Permetti agli altri di vedere la tua libreria",
            value: _isPublicProfile,
            onChanged: (val) async {
              setState(() => _isPublicProfile = val);
              if (currentUser != null) {
                await sl<UpdatePrivacyUseCase>().call(currentUser!.uid, val);
              }
            },
          ),
          SettingsTile(
            icon: Icons.lock_reset,
            title: "Cambia Password",
            onTap: () async {
              if (currentUser?.email == null) return;
              try {
                await sl<ResetPasswordUseCase>().call(currentUser!.email!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("📧 Email per il reset inviata!"),
                      backgroundColor: Colors.green,
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
            subtitle: "Versione 1.0.0 Alpha",
            onTap: () {},
          ),
          const SizedBox(height: 40),
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
              onPressed: () {},
              child: const Text("ELIMINA ACCOUNT"),
            ),
          ),
          const SizedBox(height: 50),
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
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
