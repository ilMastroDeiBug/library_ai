import 'package:flutter/material.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/auth_use_cases.dart';
import '../../main.dart'; // <-- IMPORTIAMO MAIN.DART PER AVERE AUTHGATE
import 'package:library_ai/l10n/app_localizations.dart';

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
      await sl<DeleteAccountUseCase>().call();

      if (context.mounted) {
        // FIX BUG: Rimettiamo il "Portiere" alla radice dell'app.
        // Lui vedrà subito che l'utente non c'è più e caricherà la LoginPage
        // riattivando però il listener reattivo!
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.settingsDeleteError)),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
          SizedBox(width: 10),
          Text(AppLocalizations.of(context)!.settingsDeleteAccount, style: const TextStyle(color: Colors.white)),
        ],
      ),
      content: Text(
        AppLocalizations.of(context)!.settingsDeleteWarning,
        style: const TextStyle(color: Colors.white70, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54)),
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
              : Text(
                  AppLocalizations.of(context)!.settingsDeleteForever,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
