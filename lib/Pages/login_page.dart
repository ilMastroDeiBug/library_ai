import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../AccountSetup/create_account.dart';
import '../AccountSetup/login_email.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _handleSignIn() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        print("DEBUG: Login Firebase completato!");
      }
    } catch (e) {
      print("ERRORE LOGIN: $e");
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
            // Sfumatura più profonda e moderna
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
                  // Logo con effetto Glow
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      size: 70,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Titolo stilizzato
                  const Text(
                    "LIBRARY AI",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(2, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Eleva la tua conoscenza.",
                    style: TextStyle(
                      color: Colors.cyanAccent.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 80),

                  // Bottone Google Premium
                  _buildSocialButton(
                    label: "Accedi con Google",
                    icon: Icons.g_mobiledata,
                    onPressed: _handleSignIn,
                  ),
                  const SizedBox(height: 30),

                  // Divisore
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.2)),
                      ),
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
                      Expanded(
                        child: Divider(color: Colors.white.withOpacity(0.2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Bottoni Secondari Glass
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

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 10,
        shadowColor: Colors.black45,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
