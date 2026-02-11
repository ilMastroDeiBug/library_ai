import 'package:firebase_auth/firebase_auth.dart';

class LoginService {
  /// Effettua il login con email e password.
  /// Lancia un'Exception in caso di errore per essere gestita dalla UI.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Login riuscito, nessuna return necessaria.
    } on FirebaseAuthException catch (e) {
      // Traduciamo l'errore tecnico in qualcosa di gestibile
      throw Exception(e.message ?? "Errore durante il login.");
    } catch (e) {
      throw Exception("Errore imprevisto: $e");
    }
  }
}
