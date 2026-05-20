import 'dart:ui';
import 'package:flutter/material.dart';

class SocialBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SocialBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Icone outline (non selezionata) e filled (selezionata) — stile Instagram/TikTok
  static const _items = [
    (Icons.home_outlined,         Icons.home_rounded,          'Feed'),
    (Icons.explore_outlined,      Icons.explore_rounded,       'Scopri'),
    (Icons.send_outlined,         Icons.send_rounded,          'Messaggi'),
    (Icons.person_outline_rounded,Icons.person_rounded,        'Profilo'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0C).withValues(alpha: 0.75),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 10,
              bottom: bottomPadding > 0 ? bottomPadding : 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _items.length,
                (i) => _NavItem(
                  index: i,
                  currentIndex: currentIndex,
                  iconOff: _items[i].$1,
                  iconOn:  _items[i].$2,
                  label:   _items[i].$3,
                  onTap:   onTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData iconOff;
  final IconData iconOn;
  final String label;
  final Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.iconOff,
    required this.iconOn,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    const activeColor = Colors.orangeAccent;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween(begin: 0.7, end: 1.0).animate(anim),
                child: child,
              ),
              child: Icon(
                isSelected ? iconOn : iconOff,
                key: ValueKey(isSelected),
                color: isSelected ? activeColor : Colors.white38,
                size: 26,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
