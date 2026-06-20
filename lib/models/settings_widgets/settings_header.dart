import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/l10n/app_localizations.dart';

/// Minimal centered profile header — avatar + name + email stacked vertically.
/// No card box, no backdrop filter. Pure editorial layout.
class SettingsHeader extends StatefulWidget {
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
  State<SettingsHeader> createState() => _SettingsHeaderState();
}

class _SettingsHeaderState extends State<SettingsHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _initial {
    final name = widget.user?.displayName;
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    final email = widget.user?.email ?? '';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto =
        widget.user?.photoUrl != null && widget.user!.photoUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Avatar (tapable) ────────────────────────────────────────────
        GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) {
            _ctrl.reverse();
            widget.onPhotoTap();
          },
          onTapCancel: () => _ctrl.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Avatar circle
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: widget.user!.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            errorWidget: (ctx, url, _) =>
                                _buildAvatarFallback(),
                          )
                        : _buildAvatarFallback(),
                  ),
                ),
                // Camera badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.black,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Display name ────────────────────────────────────────────────
        Text(
          widget.user?.displayName ??
              AppLocalizations.of(context)!.settingsUnknownUser,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 6),

        // ── Email ────────────────────────────────────────────────────────
        Text(
          widget.user?.email ?? '',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        if (widget.bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          // ── Bio ─────────────────────────────────────────────────────
          Text(
            widget.bio,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13,
              height: 1.5,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Text(
          _initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 36,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}
