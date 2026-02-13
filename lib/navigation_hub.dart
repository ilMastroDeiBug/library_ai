import 'package:flutter/material.dart';
import '../models/app_mode.dart';
// Page Imports
import 'pages/home_page.dart';
import 'pages/library_page.dart';

import 'pages/explore_page.dart';
import 'pages/side_menu.dart'; // We refactored this earlier
// Widget Imports
import '../models/navigation_hub_widgets/media_bottom_bar.dart';
import '../models/navigation_hub_widgets/social_bottom_bar.dart';

class NavigationHub extends StatefulWidget {
  const NavigationHub({super.key});

  @override
  State<NavigationHub> createState() => _NavigationHubState();
}

class _NavigationHubState extends State<NavigationHub> {
  // Key to control the Scaffold (Drawer) from child pages
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State
  int _selectedIndex = 0;
  AppMode _currentMode = AppMode.movies;
  bool _isSocialActive = false;

  // --- Logic Methods ---

  void _changeMode(AppMode newMode) {
    setState(() {
      _currentMode = newMode;
      _isSocialActive = false;
      _selectedIndex = 0; // Reset to Home when switching modes
    });
  }

  void _toggleSocial() {
    setState(() {
      _isSocialActive = true;
      _selectedIndex = 0;
    });
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  // --- Page Builders ---

  List<Widget> _buildMediaPages() {
    return [
      HomePage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      LibraryPage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ExplorePage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // Placeholder for AI Studio
      const Center(
        child: Text("Studio AI", style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  List<Widget> _buildSocialPages() {
    return const [
      Center(
        child: Text("Feed Social", style: TextStyle(color: Colors.white)),
      ),
      Center(
        child: Text("Amici", style: TextStyle(color: Colors.white)),
      ),
      Center(
        child: Text("Messaggi", style: TextStyle(color: Colors.white)),
      ),
      Center(
        child: Text("Profilo Social", style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121212),

      // 1. DRAWER (Refactored)
      drawer: SideMenu(
        currentMode: _currentMode,
        isSocialActive: _isSocialActive,
        onModeChanged: _changeMode,
        onSocialTap: _toggleSocial,
      ),

      // 2. BODY (Switching Logic)
      body: IndexedStack(
        index: _selectedIndex,
        children: _isSocialActive ? _buildSocialPages() : _buildMediaPages(),
      ),

      // 3. BOTTOM BAR (Modular Widgets)
      bottomNavigationBar: _isSocialActive
          ? SocialBottomBar(
              currentIndex: _selectedIndex,
              onTap: _onBottomNavTap,
            )
          : MediaBottomBar(
              currentIndex: _selectedIndex,
              currentMode: _currentMode,
              onTap: _onBottomNavTap,
            ),
    );
  }
}

