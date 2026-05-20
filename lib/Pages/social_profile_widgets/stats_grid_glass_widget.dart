import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/social_stats.dart';

// Palette colori accent – vividi ma mai neon
const _cBlue = Color(0xFF4C8EF7);
const _cPurple = Color(0xFF9B6DFF);
const _cOrange = Color(0xFFFF8C3A);
const _cTeal = Color(0xFF2DD4BF);
const _cPink = Color(0xFFFF5FA0);
const _cGold = Color(0xFFFFCC00);

class StatsGridGlassWidget extends StatelessWidget {
  final SocialStats stats;

  const StatsGridGlassWidget({super.key, required this.stats});

  String _fmt(int minutes, {bool compact = false}) {
    if (minutes == 0) return '0h';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (compact || m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LABEL SEZIONE ──────────────────────────────────────────────────
          _SectionLabel(label: 'STATISTICHE'),
          const SizedBox(height: 18),

          // ── CARD GRANDE: Ore Totali ────────────────────────────────────────
          _HeroCard(
            label: 'ORE TOTALI',
            value: _fmt(stats.totalMinutes),
            sub: 'di contenuto visto',
            accent: const Color.fromARGB(255, 247, 125, 76),
            icon: Icons.play_circle_outline_rounded,
          ),
          const SizedBox(height: 10),

          // ── ROW: Anno / Mese / Settimana ──────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MiniCard(
                    label: 'ANNO',
                    value: _fmt(stats.yearMinutes, compact: true),
                    accent: _cPurple,
                    icon: Icons.local_fire_department_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCard(
                    label: 'MESE',
                    value: _fmt(stats.monthMinutes, compact: true),
                    accent: _cOrange,
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniCard(
                    label: 'SETTIMANA',
                    value: _fmt(stats.weekMinutes, compact: true),
                    accent: _cPink,
                    icon: Icons.view_week_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── ROW: Film / Serie / Watchlist ─────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CountCard(
                    label: 'Film',
                    value: stats.moviesCount,
                    accent: _cTeal,
                    icon: Icons.movie_creation_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountCard(
                    label: 'Serie TV',
                    value: stats.tvCount,
                    accent: _cPink,
                    icon: Icons.tv_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CountCard(
                    label: 'Da vedere',
                    value: stats.watchlistCount,
                    accent: _cGold,
                    icon: Icons.bookmark_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Etichetta sezione ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card grande (Ore Totali) ─────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;
  final IconData icon;

  const _HeroCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          // Icona con glow
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 18),
          // Testo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: accent,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.28),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card mini (Anno / Mese / Settimana) ──────────────────────────────────────
class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.32),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card contatore (Film / Serie / Watchlist) ────────────────────────────────
class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final Color accent;
  final IconData icon;

  const _CountCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      accent: accent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accent, size: 18),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.32),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Container vetro nero ─────────────────────────────────────────────────────
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({
    required this.child,
    required this.accent,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Vero nero pece con minima trasparenza glass
            color: const Color(0xFF0A0A0A).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: 0.14),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              // Inner glow accent sottile
              BoxShadow(
                color: accent.withValues(alpha: 0.04),
                blurRadius: 40,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
