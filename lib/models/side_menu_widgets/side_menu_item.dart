import 'package:flutter/material.dart';

class SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const SideMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 55,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        activeColor.withOpacity(0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Indicatore laterale per lo stato attivo
                if (isSelected)
                  Positioned(
                    left: 0,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Contenuto
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? activeColor : Colors.white38,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        text,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
