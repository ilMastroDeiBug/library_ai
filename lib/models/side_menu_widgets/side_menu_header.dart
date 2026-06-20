import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import '../../Pages/settings_page.dart';

/// Redesigned side-menu header.
/// Glassmorphism card — pure black/white palette matching the home page.
class SideMenuHeader extends StatefulWidget {
  final AppUser? user;

  const SideMenuHeader({super.key, required this.user});

  @override
  State<SideMenuHeader> createState() => _SideMenuHeaderState();
}

class _SideMenuHeaderState extends State<SideMenuHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _initial {
    if (widget.user == null) return '?';
    final name = widget.user!.displayName;
    if (name != null && name.isNotEmpty) return name[0].toUpperCase();
    if (widget.user!.email.isNotEmpty) return widget.user!.email[0].toUpperCase();
    return 'A';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final hasPhoto =
        widget.user?.photoUrl != null && widget.user!.photoUrl!.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(16, topPad + 16, 16, 8),
          padding: const EdgeInsets.all(16),
          child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Circular Avatar (social-style) ──────────────────
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: hasPhoto
                                ? CachedNetworkImage(
                                    imageUrl: widget.user!.photoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) => Container(
                                      color: const Color(0xFF111111),
                                    ),
                                    errorWidget: (ctx, url, _) =>
                                        _buildInitialAvatar(),
                                  )
                                : _buildInitialAvatar(),
                          ),
                        ),
                        // Online dot
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // ── User info — Expanded to avoid overflow ───────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.user?.displayName ?? 'Utente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // FIX: Flexible inside Column prevents overflow
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Text(
                              widget.user?.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ── Settings icon ────────────────────────────────────
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Icon(
                        Icons.settings_rounded,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

  Widget _buildInitialAvatar() {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Text(
          _initial,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
