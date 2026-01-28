import 'package:flutter/material.dart';
// IMPORTANTE: Se questi import danno errore, cancellali e falli rifare a VS Code (Ctrl + .)
import 'models/app_mode.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/explore_page.dart';
import 'pages/side_menu.dart';

class NavigationHub extends StatefulWidget {
  const NavigationHub({super.key});

  @override
  State<NavigationHub> createState() => _NavigationHubState();
}

class _NavigationHubState extends State<NavigationHub> {
  // Questa chiave serve ad aprire il menu dalle altre pagine
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  AppMode _currentMode = AppMode.books;
  bool _isSocialActive = false;

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

  @override
  Widget build(BuildContext context) {
    // Definizione delle pagine principali
    final List<Widget> mediaPages = [
      // 1. HOME PAGE
      HomePage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // 2. LIBRARY PAGE
      LibraryPage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // 3. EXPLORE PAGE
      ExplorePage(
        mode: _currentMode,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // 4. AI STUDIO (Placeholder)
      const Center(
        child: Text("Studio AI", style: TextStyle(color: Colors.white)),
      ),
    ];

    // Pagine Social (Placeholder)
    final List<Widget> socialPages = [
      const Center(
        child: Text("Feed Social", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Amici", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Messaggi", style: TextStyle(color: Colors.white)),
      ),
      const Center(
        child: Text("Profilo Social", style: TextStyle(color: Colors.white)),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey, // Assegniamo la chiave allo Scaffold padre
      backgroundColor: const Color(0xFF121212),

      // Il menu laterale
      drawer: SideMenu(
        currentMode: _currentMode,
        isSocialActive: _isSocialActive,
        onModeChanged: _changeMode,
        onSocialTap: _toggleSocial,
      ),

      // Il corpo della pagina
      body: IndexedStack(
        index: _selectedIndex,
        children: _isSocialActive ? socialPages : mediaPages,
      ),

      // La barra in basso
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF121212),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          elevation: 0,
          selectedItemColor: _isSocialActive
              ? Colors.purpleAccent
              : (_currentMode == AppMode.books
                    ? Colors.cyanAccent
                    : Colors.orangeAccent),
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: _isSocialActive ? _socialItems() : _mediaItems(),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _mediaItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          _currentMode == AppMode.books
              ? Icons.menu_book_outlined
              : Icons.movie_outlined,
        ),
        label: _currentMode == AppMode.books ? 'Libreria' : 'Watchlist',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        label: 'Esplora',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_outlined),
        label: 'AI',
      ),
    ];
  }

  List<BottomNavigationBarItem> _socialItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dynamic_feed),
        label: 'Feed',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Amici'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Messaggi',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_circle_outlined),
        label: 'Profilo',
      ),
    ];
  }
}
