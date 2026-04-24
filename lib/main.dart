import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:library_ai/Pages/splash_screen.dart';
import 'firebase_options.dart';

// PAGES
import 'package:library_ai/Pages/login_page.dart';
import 'package:library_ai/AccountSetupPages/profile_setup_page.dart';
import 'package:library_ai/navigation_hub.dart';

// CLEAN ARCH IMPORTS
import 'package:library_ai/injection_container.dart' as di;
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import 'package:library_ai/services/utility_services/network_status_service.dart';
import 'package:library_ai/Pages/offline_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://vmbshnrphkmuqtjjfdah.supabase.co',
    anonKey: 'sb_publishable_MiRYZsjKtlT68nNzn2S-JQ_g-bBj_Gu',
  );

  await di.init();
  di.sl<NetworkStatusService>();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orangeAccent, // BRAND COLOR
        scaffoldBackgroundColor: Colors.black, // NERO TIKTOK/NETFLIX
        colorScheme: const ColorScheme.dark(
          primary: Colors.orangeAccent,
          secondary: Colors.orangeAccent,
          surface: Color(0xFF0A0A0C), // Grigio scurissimo
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      home: const _AppNetworkGate(child: SplashScreen()),
    );
  }
}

class _AppNetworkGate extends StatefulWidget {
  final Widget child;

  const _AppNetworkGate({required this.child});

  @override
  State<_AppNetworkGate> createState() => _AppNetworkGateState();
}

class _AppNetworkGateState extends State<_AppNetworkGate> {
  final NetworkStatusService _network = di.sl<NetworkStatusService>();
  bool _isOfflineGateLatched = false;

  @override
  void initState() {
    super.initState();
    _network.addListener(_handleNetworkStateChanged);
  }

  @override
  void dispose() {
    _network.removeListener(_handleNetworkStateChanged);
    super.dispose();
  }

  void _handleNetworkStateChanged() {
    if (!_network.hasResolvedInitialStatus) return;

    final shouldLatch = !_network.isOnline && !_network.hasEverBeenOnline;
    if (shouldLatch != _isOfflineGateLatched) {
      setState(() {
        _isOfflineGateLatched = shouldLatch || _isOfflineGateLatched;
      });
    }
  }

  void _handleOfflinePrimaryAction() {
    if (_network.isOnline) {
      setState(() {
        _isOfflineGateLatched = false;
      });
      return;
    }
    _network.checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _network,
      builder: (context, _) {
        final showOfflinePage =
            _network.hasResolvedInitialStatus &&
            (_isOfflineGateLatched ||
                (!_network.isOnline && !_network.hasEverBeenOnline));

        final showOfflineBanner =
            _network.hasResolvedInitialStatus &&
            !_network.isOnline &&
            _network.hasEverBeenOnline;

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (showOfflinePage)
              OfflinePage(
                isBackOnline: _network.isOnline,
                onRetry: _handleOfflinePrimaryAction,
              ),
            if (showOfflineBanner) const _OfflineBannerOverlay(),
          ],
        );
      },
    );
  }
}

class _OfflineBannerOverlay extends StatelessWidget {
  const _OfflineBannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [const Color(0xFFF57C33), const Color(0xFFFFA552)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.black, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sei offline. Quando la rete torna, puoi continuare senza refresh automatici.',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 1. IL PORTIERE (AuthGate) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: di.sl<AuthRepository>().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data;
          return _AuthenticatedUserGate(user: user!);
        }

        return const LoginPage();
      },
    );
  }
}

class _AuthenticatedUserGate extends StatefulWidget {
  final AppUser user;

  const _AuthenticatedUserGate({required this.user});

  @override
  State<_AuthenticatedUserGate> createState() => _AuthenticatedUserGateState();
}

class _AuthenticatedUserGateState extends State<_AuthenticatedUserGate> {
  late Future<AppUser?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _bootstrapProfile();
  }

  Future<AppUser?> _bootstrapProfile() async {
    final profile = await di.sl<GetUserDataUseCase>().call(widget.user.id);
    await di.sl<LanguageService>().syncLanguage(
      profile?.languagePreference ?? widget.user.languagePreference,
      notify: false,
    );
    return profile;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
          );
        }

        final resolvedUser = snapshot.data ?? widget.user;

        if (resolvedUser.displayName == null ||
            resolvedUser.displayName!.isEmpty) {
          return const ProfileSetupPage();
        }

        return const NavigationHub();
      },
    );
  }
}
