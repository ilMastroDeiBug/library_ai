import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isTop;
  final bool isBottom;

  // 1. AGGIUNGIAMO LE VARIABILI OPZIONALI
  final Color? iconColor;
  final Color? textColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isTop = false,
    this.isBottom = false,
    this.iconColor, // <-- Aggiunto al costruttore
    this.textColor, // <-- Aggiunto al costruttore
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      // La logica per mantenere i bordi curvi del contenitore
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(20) : Radius.zero,
        bottom: isBottom ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              // 2. USIAMO IL COLORE SE C'È, ALTRIMENTI GRIGIO STANDARD
              color: iconColor ?? Colors.white54,
              size: 22,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      // 3. USIAMO IL COLORE SE C'È, ALTRIMENTI BIANCO
                      color: textColor ?? Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
