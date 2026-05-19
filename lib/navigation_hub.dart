import 'package:flutter/material.dart';
import '../models/app_mode.dart';

// Page Imports
import 'Pages/home_page.dart';
import 'Pages/library_page.dart';
import 'Pages/explore_page.dart';
import 'Pages/side_menu.dart';
import 'Pages/studio_ai_page.dart';
import 'pages/social_profile_page.dart';


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

  // ── Lazy-build tracking ─────────────────────────────────────────────────────
  // Pages are only built when visited for the first time.
  // After that they stay alive (Offstage) and their tickers are paused when
  // hidden (TickerMode disabled) to save CPU / GPU on non-visible pages.
  final Set<int> _builtMediaPages = {0}; // Home is always built at start
  final Set<int> _builtSocialPages = {};

  void _changeMode(AppMode newMode) {
    setState(() {
      _currentMode = newMode;
      _isSocialActive = false;
      _selectedIndex = 0;
      // Reset lazy tracking so pages rebuild with the new mode
      _builtMediaPages
        ..clear()
        ..add(0);
    });
  }

  void _toggleSocial() {
    setState(() {
      _isSocialActive = true;
      _selectedIndex = 0;
      _builtSocialPages.add(0);
    });
  }

  void _onBottomNavTap(int index) {
    if (_selectedIndex == index) {
      _reselectNotifier.value = DateTime.now().millisecondsSinceEpoch;
    } else {
      setState(() {
        _selectedIndex = index;
        // Mark this page as built so it won't be skipped next time
        if (_isSocialActive) {
          _builtSocialPages.add(index);
        } else {
          _builtMediaPages.add(index);
        }
      });
    }
  }

  // ── Page factories (called fresh; lazy wrapper handles caching) ─────────────
  Widget _mediaPageAt(int index) {
    switch (index) {
      case 0:
        return HomePage(
          mode: _currentMode,
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          reselectNotifier: _reselectNotifier,
        );
      case 1:
        return LibraryPage(
          mode: _currentMode,
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 2:
        return ExplorePage(
          mode: _currentMode,
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );
      case 3:
        return const StudioAIPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _socialPageAt(int index) {
    switch (index) {
      case 3:
        return const SocialProfilePage();
      default:
        final labels = ['Feed Social', 'Amici', 'Messaggi', 'Profilo'];
        return Center(
          child: Text(
            labels[index],
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        );
    }
  }

  /// Builds a lazy stack: pages that have never been visited are skipped
  /// (SizedBox.shrink). Pages visited at least once are kept alive with
  /// Offstage. TickerMode pauses all animation controllers on hidden tabs.
  Widget _buildLazyStack({
    required int count,
    required int selected,
    required Set<int> built,
    required Widget Function(int) pageBuilder,
  }) {
    return Stack(
      children: List.generate(count, (i) {
        final isActive = i == selected;

        // Never-visited pages: render nothing (zero cost)
        if (!built.contains(i)) return const SizedBox.shrink();

        return Offstage(
          offstage: !isActive,
          child: TickerMode(
            // Disables ALL AnimationControllers on non-visible pages
            enabled: isActive,
            child: pageBuilder(i),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMedia = !_isSocialActive;
    final pageCount = isMedia ? 4 : 4;
    final built = isMedia ? _builtMediaPages : _builtSocialPages;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      extendBody: true,
      drawer: SideMenu(
        currentMode: _currentMode,
        isSocialActive: _isSocialActive,
        onModeChanged: _changeMode,
        onSocialTap: _toggleSocial,
      ),
      body: _buildLazyStack(
        count: pageCount,
        selected: _selectedIndex,
        built: built,
        pageBuilder: isMedia ? _mediaPageAt : _socialPageAt,
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
