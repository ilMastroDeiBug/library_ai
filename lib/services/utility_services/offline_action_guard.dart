import 'package:flutter/material.dart';
import '../../injection_container.dart';
import 'network_status_service.dart';

/// Utility che controlla la connessione prima di eseguire un'azione di rete.
/// Restituisce [true] se online (azione può procedere),
/// [false] se offline (mostra snackbar e blocca l'azione).
class OfflineActionGuard {
  OfflineActionGuard._();

  static bool isOnline() => sl<NetworkStatusService>().isOnline;

  /// Controlla la connessione. Se offline, mostra uno snackbar premium
  /// e restituisce false. Se online, restituisce true.
  static bool checkAndShow(BuildContext context, {String? message}) {
    if (sl<NetworkStatusService>().isOnline) return true;

    final msg = message ?? 'Sei offline. Riconnettiti per eseguire questa azione.';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFFF8C00),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return false;
  }
}
