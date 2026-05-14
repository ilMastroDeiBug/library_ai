import 'package:flutter/material.dart';
import '../models/app_mode.dart';

// Page Imports
import 'Pages/home_page.dart';
import 'Pages/library_page.dart';
import 'Pages/explore_page.dart';
import 'Pages/side_menu.dart';
import 'Pages/studio_ai_page.dart';

// Widget Imports
import '../models/navigation_hub_widgets/media_bottom_bar.dart';
import '../models/navigation_hub_widgets/social_bottom_bar.dart';

class NavigationHub extends StatefulWidget {
  const NavigationHub({super.key});

  @override
  State<NavigationHub> createState() => _NavigationHubState();
}

class _NavigationHubState extends State<NavigationHub> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  AppMode _currentMode = AppMode.movies;
  bool _isSocialActive = false;

  // IL NOTIFIER: Segnala alle pagine un "doppio tap" sulla barra
  final ValueNotifier<int> _reselectNotifier = ValueNotifier<int>(0);

  void _changeMode(AppMode newMode) {
    setState(() {
      _currentMode = newMode;
      _isSocialActive = false;
      _selectedIndex = 0;
    });
  }

  void _toggleSocial() {
    setState(() {
      _isSocialActive = true;
      _selectedIndex = 0;
    });
  }

  void _onBottomNavTap(int index) {
    if (_selectedIndex == index) {
      // Magia: Utente ha tappato sull'icona dove si trova già. Lanciamo l'evento!
      _reselectNotifier.value = DateTime.now().millisecondsSinceEpoch;
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  List<Widget> _buildMediaPages() {
    return [
      HomePage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        reselectNotifier: _reselectNotifier, // Passato in modo invisibile!
      ),
      LibraryPage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ExplorePage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      const StudioAIPage(),

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
      backgroundColor: Colors.black, // Sfondo base nero
      extendBody:
          true, // Permette alla lista di scorrere sotto la barra fluttuante
      drawer: SideMenu(
        currentMode: _currentMode,
        isSocialActive: _isSocialActive,
        onModeChanged: _changeMode,
        onSocialTap: _toggleSocial,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _isSocialActive ? _buildSocialPages() : _buildMediaPages(),
      ),
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
