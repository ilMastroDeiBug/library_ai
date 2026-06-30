import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class DeleteBookDialog extends StatelessWidget {
  final String bookTitle;
  final VoidCallback onConfirm;

  const DeleteBookDialog({
    super.key,
    required this.bookTitle,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context)!.deleteBookTitle, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteBookContent(bookTitle),
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(); // Chiude il dialog
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}
