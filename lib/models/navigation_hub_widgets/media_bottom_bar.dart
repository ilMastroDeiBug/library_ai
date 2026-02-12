import 'package:flutter/material.dart';
import '../../models/app_mode.dart';

class MediaBottomBar extends StatelessWidget {
  final int currentIndex;
  final AppMode currentMode;
  final Function(int) onTap;

  const MediaBottomBar({
    super.key,
    required this.currentIndex,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = currentMode == AppMode.books
        ? Colors.cyanAccent
        : Colors.orangeAccent;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        elevation: 0,
        selectedItemColor: activeColor,
        unselectedItemColor: Colors.grey,
        onTap: onTap,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              currentMode == AppMode.books
                  ? Icons.menu_book_outlined
                  : Icons.movie_outlined,
            ),
            label: currentMode == AppMode.books ? 'Libreria' : 'Watchlist',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Esplora',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}
