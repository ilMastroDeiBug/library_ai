import 'package:flutter/material.dart';
import '../AccountSetupPages/create_account_page.dart';
import '../AccountSetupPages/login_email_page.dart';
import '../models/login_widgets/social_login_button.dart';
import '../models/login_widgets/cascading_background.dart';

// CLEAN ARCH IMPORTS
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    // Inizializzazione animazione respiro logo
    _logoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await sl<GoogleLoginUseCase>().call();
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('Login annullato')) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Accesso con Google fallito. Riprova."),
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
      backgroundColor: const Color(0xFF0A0A0C), // Colore di base scuro
      body: Stack(
        children: [
          // 1. IL NOSTRO NUOVO SFONDO ANIMATO A CASCATA (RALLENTATO)
          const Positioned.fill(
            child: CascadingBackground(
              // Abbiamo aumentato i secondi per rendere il movimento più lento
              speed1: 110,
              speed2: 100,
              speed3: 120,
              speed4: 95,
            ),
          ),

          // 2. TUTTA LA TUA UI (Logo, Bottoni, ecc.)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Il tuo logo tondo e brillante con ANIMAZIONE DI RESPIRO
                    ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.96,
                        end: 1.04,
                      ).animate(_logoAnimation),
                      child: Container(
                        width: 170,
                        height: 170,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orangeAccent.withOpacity(0.15),
                              blurRadius: 45,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            color: Colors.black,
                            padding: const EdgeInsets.all(15),
                            child: Image.asset(
                              'assets/images/logoCine.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      "Bentornato",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Il tuo Vault dell'intrattenimento",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 60),

                    SocialLoginButton(
                      label: "Accedi con Google",
                      icon: Icons.g_mobiledata,
                      onPressed: _handleGoogleSignIn,
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 30),
                    _buildDivider(),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryButton(
                            context,
                            "Registrati",
                            const CreateAccountPage(),
                            Colors.orangeAccent,
                            isFilled: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildSecondaryButton(
                            context,
                            "Login Email",
                            const LoginEmailPage(),
                            Colors.white,
                            isFilled: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "OPPURE",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context,
    String label,
    Widget page,
    Color color, {
    required bool isFilled,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: isFilled ? Colors.black : color,
        backgroundColor: isFilled ? color : Colors.transparent,
        shadowColor: isFilled ? color.withOpacity(0.4) : Colors.transparent,
        elevation: isFilled ? 8 : 0,
        side: BorderSide(
          color: isFilled ? Colors.transparent : color.withOpacity(0.3),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}
