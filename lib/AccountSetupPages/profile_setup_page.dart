import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
// Cambiato import per includere l'Use Case che hai appena creato
import 'package:library_ai/domain/use_cases/user_cases.dart';
import '../models/login_widgets/onboarding_avatar_carousel.dart';
import '../navigation_hub.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _usernameController = TextEditingController();
  String _selectedAvatar = "";
  bool _isLoading = false;

  // I Seeds originali che generano i Bottts/Micah più belli
  final List<String> _avatarSeeds = [
    'Felix',
    'Jude',
    'Aneka',
    'Milo',
    'Luna',
    'Leo',
    'Avery',
    'Eden',
    'Riley',
    'Cleo',
    'Oliver',
    'Jasper',
    'Harper',
    'Quinn',
    'Rowan',
  ];

  // Genera dinamicamente le URL per il carosello
  late final List<String> _premiumAvatars = _avatarSeeds
      .map(
        (seed) =>
            'https://api.dicebear.com/9.x/micah/png?seed=$seed&backgroundColor=transparent&size=150',
      )
      .toList();

  Future<void> _saveProfile() async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inserisci un nome valido."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Recupera l'utente corrente per avere l'ID
      final user = sl<AuthRepository>().currentUser;
      if (user == null) {
        throw Exception("Sessione non trovata. Effettua nuovamente il login.");
      }

      // 2. Salva il Nome Visualizzato usando il TUO nuovo Use Case
      await sl<UpdateNameUseCase>().call(user.id, name);

      // 3. Salva l'Avatar
      if (_selectedAvatar.isNotEmpty) {
        await sl<UpdateAvatarUseCase>().call(user.id, _selectedAvatar);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Benvenuto a bordo di CineShare.",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );

        // Naviga alla home eliminando lo stack di navigazione
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const NavigationHub()),
          (route) => false,
        );
      }
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // EFFETTO GLOWING ORB SULLO SFONDO
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orangeAccent.withOpacity(0.15),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // CONTENUTO PRINCIPALE
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Il tuo Profilo",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Scegli un avatar e un nome visualizzato\nper farti riconoscere nella community.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Carosello Avatar
                    OnboardingAvatarCarousel(
                      avatars: _premiumAvatars,
                      onAvatarSelected: (url) {
                        _selectedAvatar = url;
                      },
                    ),

                    const SizedBox(height: 50),

                    // Input Nome
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _usernameController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "Es. Cinefilo99",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Pulsante di Completamento
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orangeAccent.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'INIZIA AVVENTURA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
