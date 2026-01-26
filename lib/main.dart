import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:library_ai/Pages/login_page.dart';
import 'firebase_options.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Qui decidiamo quale pagina mostrare all'avvio
      home: const AuthGate(),
    );
  }
}

// --- 1. IL PORTIERE (Gestisce il traffico) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder ascolta Firebase in tempo reale
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data;
          if (user?.displayName == null || user!.displayName!.isEmpty) {
            return const ProfileSetupPage();
          }
          return const NavigationHub(); // <--- Cambia da LibraryPage a NavigationHub
        }
        return const LoginPage();
      },
    );
  }
}

// --- 2. LA PAGINA DELLA LIBRERIA (Dove arriverai) ---

// --- 2.5 LA PAGINA DI CREAZIONE ACCOUNT ---

// --- 3. LA PAGINA DI LOGIN CON GOOGLE (Quella che hai già visto) ---
