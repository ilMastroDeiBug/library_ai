import 'package:flutter/material.dart';

/// Flat settings tile — no icon box, just icon + text + chevron.
/// Hairline divider between items. Pure black/white palette.
class SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isTop;
  final bool isBottom;
  final Color iconColor;
  final Color? textColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isTop = false,
    this.isBottom = false,
    this.iconColor = Colors.white,
    this.textColor,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: !widget.isBottom
                ? Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07),
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon (no box) ─────────────────────────────────────────
              Icon(
                widget.icon,
                color: widget.textColor ??
                    Colors.white.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 16),

              // ── Text block ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.textColor ?? Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: widget.textColor?.withValues(alpha: 0.60) ??
                            Colors.white.withValues(alpha: 0.35),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Chevron ───────────────────────────────────────────────
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.20),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
