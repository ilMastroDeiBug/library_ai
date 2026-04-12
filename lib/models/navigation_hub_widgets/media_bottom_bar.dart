import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/app_mode.dart';

class MediaBottomBar extends StatelessWidget {
  final int currentIndex;
  final AppMode currentMode;
  final Function(int) onTap;

  const MediaBottomBar({
    super.key,
    required this.currentIndex,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calcoliamo lo spazio per la "Home Indicator" (la barra di sistema in basso)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      // Evita che l'effetto sfocato sbavi fuori dal menu
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 25,
          sigmaY: 25,
        ), // Effetto vetro bello denso
        child: Container(
          decoration: BoxDecoration(
            color: const Color(
              0xFF0A0A0C,
            ).withOpacity(0.75), // Sfondo scurissimo semitrasparente
            border: Border(
              // Bordino superiore sottilissimo per dare profondità al vetro
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: bottomPadding > 0
                ? bottomPadding
                : 16, // Rispetta il bordo del telefono
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(
                1,
                currentMode == AppMode.books
                    ? Icons.menu_book_rounded
                    : Icons.movie_filter_rounded,
                currentMode == AppMode.books ? 'Vault' : 'Watchlist',
              ),
              _buildNavItem(2, Icons.explore_rounded, 'Esplora'),
              _buildNavItem(3, Icons.auto_awesome_rounded, 'AI'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    const activeColor = Colors.orangeAccent;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        // L'animazione a pillola RIMANE per la singola icona selezionata!
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.white54,
              size:
                  26, // Leggermente più grandi ora che abbiamo larghezza piena
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
