import 'package:flutter/material.dart'; // Serve solo per il tipo User in alcuni casi
import '../services/user_services.dart'; // Importa il Service

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Istanziamo il service
  final UserService _userService = UserService();

  // Stato locale UI
  bool _isPublicProfile = true;
  bool _notificationsEnabled = false;
  String _bio = "Caricamento bio...";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Funzione wrapper per caricare i dati dal service
  Future<void> _loadData() async {
    final data = await _userService.getUserData();
    if (mounted && data != null) {
      setState(() {
        _bio = data['bio'] ?? "Nessuna biografia.";
        _isPublicProfile = data['isPublic'] ?? true;
      });
    }
  }

  // --- DIALOGHI UI (View Logic) ---

  Future<void> _showNameDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _userService.currentUser?.displayName,
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Modifica Nome",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Inserisci nuovo nome",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ANNULLA",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _userService.updateName(
                  controller.text.trim(),
                ); // CHIAMA IL SERVICE
                setState(() {}); // Aggiorna UI per mostrare il nuovo nome
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("SALVA"),
          ),
        ],
      ),
    );
  }

  Future<void> _showBioDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _bio == "Nessuna biografia." ? "" : _bio,
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("La tua Bio", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Scrivi qualcosa...",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ANNULLA",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await _userService.updateBio(
                controller.text.trim(),
              ); // CHIAMA IL SERVICE
              setState(() => _bio = controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("SALVA"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nota: usiamo il getter del service per l'utente corrente
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

          // HEADER PROFILO
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Upload foto in arrivo con Firebase Storage!"),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? "Utente",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildSectionHeader("MODIFICA DATI"),
          _buildSettingsTile(
            icon: Icons.edit,
            title: "Nome Visualizzato",
            subtitle: user?.displayName ?? "Tocca per impostare",
            onTap: _showNameDialog, // Apre il dialog
          ),
          _buildSettingsTile(
            icon: Icons.text_snippet,
            title: "Biografia",
            subtitle: _bio.isEmpty ? "Raccontaci di te" : _bio,
            onTap: _showBioDialog, // Apre il dialog
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: user?.email ?? "Nessuna email",
            onTap: null,
          ),

          const SizedBox(height: 20),

          _buildSectionHeader("PRIVACY & SICUREZZA"),
          _buildSwitchTile(
            title: "Profilo Pubblico",
            subtitle: "Permetti agli altri di vedere la tua libreria",
            value: _isPublicProfile,
            onChanged: (val) async {
              setState(() => _isPublicProfile = val);
              await _userService.updatePrivacyProfile(val); // CHIAMA IL SERVICE
            },
          ),

          // --- LOGICA CAMBIA PASSWORD ---
          _buildSettingsTile(
            icon: Icons.lock_reset,
            title: "Cambia Password",
            onTap: () async {
              try {
                // Chiamiamo il service intelligente
                await _userService.sendPasswordReset();

                // Se non lancia errori, mostriamo successo
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "📧 Email per il reset inviata! Controlla la posta.",
                      ),
                      backgroundColor: Colors.green, // Verde per successo
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                // Pulizia messaggio errore
                final errorMessage = e.toString().replaceAll("Exception: ", "");

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        errorMessage,
                      ), // Messaggio preciso (es. "Accedi con Google...")
                      backgroundColor: Colors.redAccent, // Rosso per errore
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 20),

          _buildSectionHeader("PREFERENZE APP"),
          _buildSwitchTile(
            title: "Notifiche Push",
            subtitle: "Ricevi aggiornamenti e promemoria",
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
            },
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: "Informazioni App",
            subtitle: "Versione 1.0.0 Alpha",
            onTap: () {},
          ),

          const SizedBox(height: 40),

          // --- DANGER ZONE ---
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

  // --- WIDGET HELPER ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.cyanAccent.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    IconData? icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: Colors.white70) : null,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.white54)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      activeColor: Colors.cyanAccent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
