import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Gestisce il flusso completo di Login con Google
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger del flusso Google (Popup o App)
      // Prima facciamo signOut per forzare la scelta dell'account se necessario
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // L'utente ha annullato il login
        return null;
      }

      // 2. Otteniamo i dettagli dell'autenticazione dalla richiesta
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Creiamo le credenziali per Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Usiamo le credenziali per entrare in Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } catch (e) {
      print("Errore AuthService Google: $e");
      throw Exception("Impossibile accedere con Google. Riprova.");
    }
  }

  // Qui potresti aggiungere anche loginWithEmail, register, logout...
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
