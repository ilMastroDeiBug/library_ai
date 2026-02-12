import 'package:flutter/material.dart';
import '../services/utility_services/auth_service.dart';
import '../AccountSetupPages/create_account_page.dart';
import '../AccountSetupPages/login_email_page.dart';
// Import Widget Modulari
import '../models/login_widgets/login_logo.dart';
import '../models/login_widgets/social_login_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // Non serve navigare manualmente: il AuthGate nel main.dart
      // rileverà il cambio di stato e porterà l'utente alla Home.
      print("DEBUG: Login Google riuscito");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. LOGO E TITOLO (Widget Estratto)
                  const LoginLogo(),

                  const SizedBox(height: 80),

                  // 2. BOTTONE GOOGLE (Widget Estratto + Logica Service)
                  SocialLoginButton(
                    label: "Accedi con Google",
                    icon: Icons.g_mobiledata,
                    onPressed: _handleGoogleSignIn,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 30),

                  // 3. DIVISORE
                  _buildDivider(),

                  const SizedBox(height: 30),

                  // 4. BOTTONI SECONDARI
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryButton(
                          context,
                          "Registrati",
                          const CreateAccountPage(),
                          Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildSecondaryButton(
                          context,
                          "Login Email",
                          const LoginEmailPage(),
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Piccoli helper locali per UI che non meritano un file a parte (ancora)
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "OPPURE",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    String label,
    Widget page,
    Color color,
  ) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
