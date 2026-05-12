import 'package:flutter/material.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class SocialBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SocialBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        elevation: 0,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dynamic_feed),
            label: AppLocalizations.of(context)!.socialFeed,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: AppLocalizations.of(context)!.socialFriends,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            label: AppLocalizations.of(context)!.socialMessages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            label: AppLocalizations.of(context)!.socialProfile,
          ),
        ],
      ),
    );
  }
}
