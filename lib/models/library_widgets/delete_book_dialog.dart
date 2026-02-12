import 'dart:ui';
import 'package:flutter/material.dart';

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
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 10),
            Text("Eliminare?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "Rimuovere \"$bookTitle\" dalla libreria è un'azione irreversibile.",
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "ANNULLA",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
              elevation: 0,
            ),
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(); // Chiude il dialog
            },
            child: const Text("ELIMINA"),
          ),
        ],
      ),
    );
  }
}
