import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_mode.dart';
import 'package:library_ai/l10n/app_localizations.dart';

/// Switcher "Film / Serie TV" stile pill compatto.
/// Palette: bianco/grigio-freddo su trasparente, zero colori sgargianti.
class HomeCinemaSwitcher extends StatelessWidget {
  final CinemaType selectedType;
  final ValueChanged<CinemaType> onTypeChanged;

  const HomeCinemaSwitcher({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PillTab(
                label: AppLocalizations.of(context)!.movies,
                isActive: selectedType == CinemaType.movies,
                onTap: () => onTypeChanged(CinemaType.movies),
              ),
              _PillTab(
                label: AppLocalizations.of(context)!.tvSeries,
                isActive: selectedType == CinemaType.tvSeries,
                onTap: () => onTypeChanged(CinemaType.tvSeries),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.1,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
