import 'package:flutter/material.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/auth_use_cases.dart'; // Metti il percorso giusto
import '../../pages/login_page.dart'; // Metti il percorso della tua pagina iniziale

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _isLoading = false;

  Future<void> _handleDelete(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      // Chiamiamo il nostro purissimo Use Case!
      await sl<DeleteAccountUseCase>().call();

      if (context.mounted) {
        // Rimuove tutte le pagine e riporta l'utente alla schermata di Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ), // O SplashScreen
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Errore durante l'eliminazione.")),
        );
        Navigator.pop(context); // Chiude il dialog in caso di errore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
          SizedBox(width: 10),
          Text("Elimina Account", style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Text(
        "Sei sicuro di voler eliminare il tuo account?\n\nQuesta azione è IRREVERSIBILE. Tutti i tuoi salvataggi, librerie e analisi AI andranno persi per sempre.",
        style: TextStyle(color: Colors.white70, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Annulla", style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isLoading ? null : () => _handleDelete(context),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Elimina per sempre",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
