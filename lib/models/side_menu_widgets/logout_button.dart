import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import '../../../main.dart'; // IMPORTANTE: per riavviare AuthGate!

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await sl<LogoutUseCase>().call();
        if (context.mounted) {
          // FIX BUG: Ricarichiamo la radice per evitare lo schermo bloccato
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
        }
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1), // Sfondo rosso leggero
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded, // Icona più moderna
              color: Colors.redAccent.withOpacity(0.9),
              size: 20,
            ),
            const SizedBox(width: 10),
            const Text(
              "Disconnetti",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
