import 'package:firebase_auth/firebase_auth.dart';

class CreateAccountService {
  // Singleton pattern (Opzionale, ma stile C# service):
  // Per ora usiamo una classe semplice instanziabile, ma potresti farla static.

  /// Tenta di registrare l'utente su Firebase.
  /// Se fallisce, lancia un'Exception con un messaggio leggibile.
  Future<void> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Se arriva qui, è andato tutto bene. Non ritorna nulla (void).
    } on FirebaseAuthException catch (e) {
      // QUI avviene la magia dell'incapsulamento.
      // Intercettiamo l'errore di Firebase e lo trasformiamo in un errore generico.
      // Così la UI non ha bisogno di conoscere il codice di errore "weak-password" ecc.
      throw Exception(
        e.message ?? "Si è verificato un errore durante la registrazione.",
      );
    } catch (e) {
      throw Exception("Errore imprevisto: $e");
    }
  }
}
