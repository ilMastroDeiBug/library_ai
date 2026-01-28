import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:library_ai/Pages/login_page.dart';
import 'services/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:library_ai/AccountSetup/profile_setup.dart';
import 'package:library_ai/navigation_hub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library AI',
      debugShowCheckedModeBanner:
          false, // Rimuove la scritta "DEBUG" in alto a destra
      // --- TEMA GLOBALE SCURO ---
      theme: ThemeData(
        brightness: Brightness.dark, // Dice a Flutter: "Siamo al buio"
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Lo sfondo predefinito per tutte le pagine
        // Impostiamo i colori base
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E1E), // Colore delle Card/Dialoghi
        ),

        // Stile predefinito per le AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),

        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}

// --- 1. IL PORTIERE (AuthGate) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se sta caricando (es. avvio lento), mostra una rotella nera su sfondo scuro
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data;
          // Controllo se il nome è vuoto (Profile Setup)
          if (user?.displayName == null || user!.displayName!.isEmpty) {
            return const ProfileSetupPage();
          }
          // Tutto ok -> Hub di Navigazione
          return const NavigationHub();
        }

        // Non loggato -> Login
        return const LoginPage();
      },
    );
  }
}
