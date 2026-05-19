import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:library_ai/l10n/app_localizations.dart'; // File generato fisicamente in lib/l10n

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INIZIALIZZAZIONE FIREBASE
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Errore Firebase Init: $e");
  }

  // 2. INIZIALIZZAZIONE SUPABASE
  try {
    await Supabase.initialize(
      url: 'https://vmbshnrphkmuqtjjfdah.supabase.co',
      anonKey: 'sb_publishable_MiRYZsjKtlT68nNzn2S-JQ_g-bBj_Gu',
    );
  } catch (e) {
    debugPrint("Errore Supabase Init: $e");
  }

  // 3. INIZIALIZZAZIONE HIVE (OTTIMIZZATO PER WEB E MOBILE)
  try {
    await Hive.initFlutter();

    // Apriamo i box. Sul web usa IndexedDB, su Mobile usa i file.
    await Hive.openBox('cinelib_cache');
    await Hive.openBox('tmdb_cache');
  } catch (e) {
    debugPrint("Errore Hive Init: $e");
  }

  // 4. INIEZIONE DELLE DIPENDENZE
  try {
    await di.init();
    di
        .sl<
          NetworkStatusService
        >(); // Inizializzato per usarlo nel resto dell'app
  } catch (e) {
    debugPrint("Errore Dependency Injection: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: di.sl<LanguageService>(),
      builder: (context, _) {
        return MaterialApp(
          title: 'MatchCut',
          debugShowCheckedModeBanner: false,
          locale: Locale(di.sl<LanguageService>().shortCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.orangeAccent,
            scaffoldBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark(
              primary: Colors.orangeAccent,
              secondary: Colors.orangeAccent,
              surface: Color(0xFF0A0A0C),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
            ),
            useMaterial3: true,
          ),
          // LA MAGIA È QUI: Il builder avvolge l'intera app (Navigator)
          builder: (context, child) {
            return GlobalNetworkBanner(child: child ?? const SizedBox.shrink());
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

// --- WIDGET BANNER OFFLINE GLOBALE ---
class GlobalNetworkBanner extends StatefulWidget {
  final Widget child;
  const GlobalNetworkBanner({super.key, required this.child});

  @override
  State<GlobalNetworkBanner> createState() => _GlobalNetworkBannerState();
}

class _GlobalNetworkBannerState extends State<GlobalNetworkBanner> {
  bool _isVisible = false;
  Timer? _hideTimer;
  late final NetworkStatusService _networkService;

  @override
  void initState() {
    super.initState();
    _networkService = di.sl<NetworkStatusService>();
    _networkService.addListener(_onNetworkChange);
    _onNetworkChange();
  }

  @override
  void dispose() {
    _networkService.removeListener(_onNetworkChange);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onNetworkChange() {
    if (!mounted) return;

    final isOffline = !_networkService.isOnline;
    final hasResolved = _networkService.hasResolvedInitialStatus;

    if (hasResolved && isOffline) {
      setState(() => _isVisible = true);
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });
    } else {
      if (_isVisible) {
        setState(() => _isVisible = false);
      }
      _hideTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
          top: _isVisible ? 0 : -150,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161618),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.orangeAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.offlineTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.offlineSubtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
