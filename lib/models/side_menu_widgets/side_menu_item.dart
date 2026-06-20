import 'package:flutter/material.dart';

/// Premium animated side menu item.
/// Pure black/white palette — consistent with the home page.
/// Highlights with an animated left accent bar + white background tint when selected.
class SideMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;
  final String? badge;

  const SideMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
    this.badge,
  });

  @override
  State<SideMenuItem> createState() => _SideMenuItemState();
}

class _SideMenuItemState extends State<SideMenuItem>
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
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 50,
            decoration: BoxDecoration(
              // White tint on selected, transparent otherwise
              color: widget.isSelected
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // ── Left accent bar ──────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 3,
                  height: widget.isSelected ? 26 : 0,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: widget.activeColor,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
                if (!widget.isSelected) const SizedBox(width: 17),

                // ── Icon ────────────────────────────────────────────────
                Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.40),
                  size: 21,
                ),
                const SizedBox(width: 14),

                // ── Label ───────────────────────────────────────────────
                Expanded(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      fontWeight: widget.isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                // ── Optional badge ───────────────────────────────────────
                if (widget.badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.activeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.activeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      widget.badge!,
                      style: TextStyle(
                        color: widget.activeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
