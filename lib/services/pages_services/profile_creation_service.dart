import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  /// Aggiorna il nome visualizzato (DisplayName) dell'utente corrente.
  Future<void> updateDisplayName(String newName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          "Nessun utente loggato. Impossibile aggiornare il profilo.",
        );
      }

      if (newName.isEmpty) {
        throw Exception("Il nome non può essere vuoto.");
      }

      // Aggiorna il nome su Firebase Auth
      await user.updateDisplayName(newName);

      // Ricarica l'utente per assicurarsi che i dati siano freschi ovunque
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw Exception(
        e.message ?? "Errore durante l'aggiornamento del profilo.",
      );
    } catch (e) {
      throw Exception("Errore imprevisto: $e");
    }
  }
}
