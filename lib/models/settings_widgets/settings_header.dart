import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/app_user.dart';

class SettingsHeader extends StatelessWidget {
  final AppUser? user;
  final String bio;
  final VoidCallback onPhotoTap;

  const SettingsHeader({
    super.key,
    required this.user,
    required this.bio,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF161618),
            const Color(0xFF161618).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar con effetto Glow e logica dinamica
          GestureDetector(
            onTap: onPhotoTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.orangeAccent.withOpacity(0.8),
                    Colors.deepOrangeAccent.withOpacity(0.4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.black,
                // LOGICA: Se esiste l'URL dell'avatar lo mostra, altrimenti mostra il logo
                child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user!.photoUrl!,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/images/logoCine.png', // Usato il logo da te indicato
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Informazioni Utente
          Text(
            user?.displayName ?? "Utente Misterioso",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              user?.email ?? "",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Sezione Biografia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: Colors.orangeAccent.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
