import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import '../../Pages/settings_page.dart';

class SideMenuHeader extends StatelessWidget {
  final AppUser? user;

  const SideMenuHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Calcolo dell'iniziale di riserva (fallback)
    final String initial = user != null
        ? ((user!.displayName?.isNotEmpty ?? false)
              ? user!.displayName![0].toUpperCase()
              : (user!.email.isNotEmpty ? user!.email[0].toUpperCase() : 'A'))
        : '?';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        20,
      ),
      child: Row(
        children: [
          // Avatar Premium (Bordo Arancione)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.orangeAccent.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF1E1E1E),
              // LOGICA IN TEMPO REALE: Mostra la foto se esiste, altrimenti l'iniziale
              child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user!.photoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        // Se l'immagine non si carica per problemi di rete, mostra l'iniziale
                        errorBuilder: (context, error, stackTrace) => Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Testi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? "Esploratore Ignoto",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? "user@cineshare.com",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tasto Impostazioni Integrato
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white54),
            splashRadius: 24,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
