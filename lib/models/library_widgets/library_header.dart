import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import '../../pages/settings_page.dart';
import 'package:library_ai/domain/use_cases/social_use_cases.dart';
import 'package:library_ai/domain/entities/social_stats.dart';
import 'package:library_ai/injection_container.dart';
import '../app_mode.dart';
import 'package:library_ai/l10n/app_localizations.dart';

// Pre-shuffled cover list — fixed seed so order is stable across rebuilds
final List<String> _shuffledCovers = () {
  final list = List<String>.generate(
    30,
    (i) => 'assets/images/covers/cover_${i + 1}.jpg',
  );
  list.shuffle(math.Random(7)); // seed = 7 → deterministic mixed order
  return list;
}();

class LibraryHeader extends StatelessWidget {
  final AppMode mode;
  final AppUser? user;
  final VoidCallback onOpenDrawer;

  const LibraryHeader({
    super.key,
    required this.mode,
    required this.user,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Colors.white;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── LAYER 0: Static cover mosaic ─────────────────────────────────────
        Positioned.fill(child: _StaticCoverMosaic()),

        // ── LAYER 1: Gradient overlay (dark at top/bottom, lighter in middle)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.80),
                  Colors.black.withValues(alpha: 0.52),
                  Colors.black.withValues(alpha: 0.80),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // ── LAYER 2: Content ─────────────────────────────────────────────
        // Layout a colonna: menu in cima, titolo+chip ancorati al fondo.
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. MENU E PROFILO (in cima)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onOpenDrawer,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    _buildProfileAvatar(context, accentColor),
                  ],
                ),

                // 2. TITOLO + CHIP (ancorati in basso)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode == AppMode.books
                          ? AppLocalizations.of(context)!.libHeaderVault
                          : AppLocalizations.of(context)!.libHeaderWatchlist,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -1.5,
                      ),
                    ),
                    if (mode != AppMode.books && user != null) ...[
                      const SizedBox(height: 12),
                      _buildWatchTimeChip(user!.id),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWatchTimeChip(String userId) {
    return FutureBuilder<SocialStats>(
      future: sl<GetSocialStatsUseCase>().call(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final stats = snapshot.data!;

        final h = stats.totalMinutes ~/ 60;
        final m = stats.totalMinutes % 60;
        final timeStr = m > 0 ? '${h}h ${m}m' : '${h}h';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'viste',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(BuildContext context, Color accent) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      ),
      child: Hero(
        tag: 'profile_avatar_header',
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1E1E1E),
            child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user!.photoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Text(
                        user?.displayName != null &&
                                user!.displayName!.isNotEmpty
                            ? user!.displayName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : Text(
                    user?.displayName != null && user!.displayName!.isNotEmpty
                        ? user!.displayName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Static cover mosaic widget ───────────────────────────────────────────────
class _StaticCoverMosaic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const double targetTileH = 76.0; // ~2:3 poster ratio at ~52px wide
    const double targetTileW = 52.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Safety checks for invalid or infinite constraints
        double maxWidth = constraints.maxWidth;
        double maxHeight = constraints.maxHeight;

        if (maxWidth <= 0 || maxHeight <= 0) return const SizedBox();
        if (maxWidth == double.infinity)
          maxWidth = MediaQuery.of(context).size.width;
        if (maxHeight == double.infinity) maxHeight = 300.0; // Fallback height

        // Compute exact tile width so tiles fill the row with zero remainder gap
        final cols = (maxWidth / targetTileW).ceil();
        final tileW = maxWidth / cols;
        final tileH = tileW * (targetTileH / targetTileW); // preserve ratio
        final rows = (maxHeight / tileH).ceil() + 1;
        final totalTiles = cols * rows;

        return SizedBox(
          width: maxWidth,
          height: maxHeight,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: maxWidth + 2.0, // Allow slight bleed for precision
              maxHeight: double.infinity,
              alignment: Alignment.topLeft,
              child: Wrap(
                children: List.generate(totalTiles, (i) {
                  return SizedBox(
                    width: tileW,
                    height: tileH,
                    child: Image.asset(
                      _shuffledCovers[i % _shuffledCovers.length],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF1C1C1E)),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
