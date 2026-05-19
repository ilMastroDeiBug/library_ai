import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/entities/social_stats.dart';

/// Header del profilo: avatar, titolo esperienza, contatori, bio, bottone modifica.
class ProfileHeader extends StatelessWidget {
  final AppUser user;
  final SocialStats stats;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          // ── Avatar ───────────────────────────────────────────────────────────
          _Avatar(photoUrl: user.photoUrl, size: 88),
          const SizedBox(height: 14),

          // ── Nome + Titolo esperienza ──────────────────────────────────────────
          Text(
            user.displayName ?? 'Cinefilo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _computeExperienceTitle(stats.vaultCount),
            style: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          // ── Contatori ─────────────────────────────────────────────────────────
          _StatsRow(stats: stats),

          // ── Bio ───────────────────────────────────────────────────────────────
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              user.bio!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 22),

          // ── Pulsante Modifica Profilo ─────────────────────────────────────────
          _EditProfileButton(onTap: () => _openEditSheet(context, user)),
        ],
      ),
    );
  }

  String _computeExperienceTitle(int count) {
    if (count < 10) return '✦ Esordiente';
    if (count < 30) return '✦ Appassionato';
    if (count < 75) return '✦ Cinefilo Seriale';
    if (count < 150) return '✦ Critico in Erba';
    if (count < 300) return '✦ Cinefilo Accanito';
    if (count < 500) return '✦ Analista di Gusto';
    return '✦ Maestro del Vault';
  }

  void _openEditSheet(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final double size;

  const _Avatar({this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _AvatarPlaceholder(size: size),
                errorWidget: (_, __, ___) => _AvatarPlaceholder(size: size),
              )
            : _AvatarPlaceholder(size: size),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final double size;
  const _AvatarPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFF1E1E1E),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white24,
        size: size * 0.5,
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SocialStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatCell(
          label: 'Seguiti',
          value: stats.followingCount,
        ),
        _StatDivider(),
        _StatCell(
          label: 'Follower',
          value: stats.followersCount,
        ),
        _StatDivider(),
        _StatCell(
          label: 'Nel Vault',
          value: stats.vaultCount,
          accent: true,
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  final bool accent;

  const _StatCell({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: accent ? Colors.orangeAccent : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.08),
    );
  }
}

// ── Edit Profile Button ───────────────────────────────────────────────────────

class _EditProfileButton extends StatefulWidget {
  final VoidCallback onTap;
  const _EditProfileButton({required this.onTap});

  @override
  State<_EditProfileButton> createState() => _EditProfileButtonState();
}

class _EditProfileButtonState extends State<_EditProfileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: const Text(
            'Modifica Profilo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatelessWidget {
  final AppUser user;
  const _EditProfileSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Modifica Profilo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline, color: Colors.white54),
            title: const Text('Nome', style: TextStyle(color: Colors.white70, fontSize: 13)),
            subtitle: Text(
              user.displayName ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings for profile editing
            },
          ),
          Divider(color: Colors.white.withOpacity(0.06)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline, color: Colors.white54),
            title: const Text('Bio', style: TextStyle(color: Colors.white70, fontSize: 13)),
            subtitle: Text(
              user.bio?.isNotEmpty == true ? user.bio! : 'Aggiungi una bio...',
              style: TextStyle(
                color: user.bio?.isNotEmpty == true ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
