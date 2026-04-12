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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://vmbshnrphkmuqtjjfdah.supabase.co',
    anonKey: 'sb_publishable_MiRYZsjKtlT68nNzn2S-JQ_g-bBj_Gu',
  );

  await di.init();

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
      home: const SplashScreen(),
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

          if (user?.displayName == null || user!.displayName!.isEmpty) {
            return const ProfileSetupPage();
          }

          return const NavigationHub();
        }

        return const LoginPage();
      },
    );
  }
}
