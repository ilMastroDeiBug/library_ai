import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:library_ai/Pages/splash_screen.dart';
import 'firebase_options.dart';

// PAGES
import 'package:library_ai/Pages/login_page.dart';
import 'package:library_ai/AccountSetupPages/profile_setup_page.dart';
import 'package:library_ai/navigation_hub.dart';

// CLEAN ARCH IMPORTS - Usa i percorsi assoluti package:
import 'package:library_ai/injection_container.dart' as di;
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/entities/app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // INIZIALIZZA IL SERVICE LOCATOR (Fondamentale!)
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- 1. IL PORTIERE (AuthGate) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // ASCOLTA LO STREAM DEL REPOSITORY (Non Firebase diretto!)
    return StreamBuilder<AppUser?>(
      stream: di.sl<AuthRepository>().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data;

          // Se il nome è vuoto, manda al Profile Setup
          if (user?.displayName == null || user!.displayName!.isEmpty) {
            return const ProfileSetupPage();
          }

          // Utente completo -> Home
          return const NavigationHub();
        }

        // Nessun utente -> Login
        return const LoginPage();
      },
    );
  }
}
