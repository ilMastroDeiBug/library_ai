import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Funzioni provvisorie per gestire i click
  void _openDonation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Presto potrai supportarmi con Ko-fi o PayPal!"),
        backgroundColor: Colors.orangeAccent,
      ),
    );
    // TODO: Usa url_launcher per aprire il link a Ko-fi / BuyMeACoffee / PayPal
  }

  void _showRewardedAd(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Caricamento sponsor... (Integrazione AdMob in arrivo)"),
        backgroundColor: Colors.white,
      ),
    );
    // TODO: Integra Google Mobile Ads (Rewarded Video Ad)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C), // Tema CineShare
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER: Logo e Titolo
            Center(
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/logoCine.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                "CineShare",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Center(
              child: Text(
                "Versione 1.0.0 (Beta)",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // LA STORIA
            const Text(
              "Dietro le quinte",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: const [
                    TextSpan(
                      text: "Ciao! Sono lo sviluppatore di CineShare e ho ",
                    ),
                    TextSpan(
                      text: "16 anni",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    TextSpan(
                      text:
                          ".\n\nHo costruito questa piattaforma da solo, unendo gestione dei media e Intelligenza Artificiale.\n\n",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // OBIETTIVO FUTURO
            const Text(
              "Il Prossimo Obiettivo",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orangeAccent.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apple, color: Colors.white, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sbarco su iOS & Libri",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "L'account sviluppatore Apple costa 99\$/anno. Con il tuo supporto porterò CineShare su iPhone e sbloccherò l'intera sezione Libri, grazie al servizio di ISBN!",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SEZIONE SUPPORTO
            const Text(
              "Come puoi aiutarmi?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            _buildSupportButton(
              icon: Icons.local_cafe_rounded,
              title: "Offrimi un Caffè (Server)",
              subtitle: "Supporta questo progetto",
              color: Colors.orangeAccent,
              onTap: () => _openDonation(context),
            ),
            const SizedBox(height: 12),
            _buildSupportButton(
              icon: Icons.play_circle_outline_rounded,
              title: "Guarda uno Sponsor",
              subtitle: "Supportami gratis guardando un video di 30s",
              color: const Color.fromARGB(255, 248, 248, 248),
              onTap: () => _showRewardedAd(context),
            ),
            const SizedBox(height: 12),
            _buildSupportButton(
              icon: Icons.star_rate_rounded,
              title: "Lascia 5 Stelle",
              subtitle: "Aiuta l'algoritmo a far crescere l'app",
              color: Colors.yellow.shade700,
              onTap: () {
                // TODO: Integrare in_app_review
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
