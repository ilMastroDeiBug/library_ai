import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter per l'utente corrente
  User? get currentUser => _auth.currentUser;

  // 1. CARICA DATI UTENTE
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      return doc.data();
    } catch (e) {
      print("Errore nel caricamento dati: $e");
      return null;
    }
  }

  // 2. AGGIORNA NOME (Auth + Firestore)
  Future<void> updateName(String newName) async {
    if (currentUser == null || newName.isEmpty) return;

    try {
      // Aggiorna Auth (Sessione locale)
      await currentUser!.updateDisplayName(newName);

      // Aggiorna Firestore (Database)
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'displayName': newName,
        'email': currentUser!.email,
      }, SetOptions(merge: true));

      // Ricarica l'utente locale per vedere le modifiche subito
      await currentUser!.reload();
    } catch (e) {
      throw Exception("Impossibile aggiornare il nome: $e");
    }
  }

  // 3. AGGIORNA BIO (Solo Firestore)
  Future<void> updateBio(String newBio) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'bio': newBio,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Impossibile aggiornare la bio: $e");
    }
  }

  // 4. AGGIORNA PRIVACY (Solo Firestore)
  Future<void> updatePrivacyProfile(bool isPublic) async {
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser!.uid).set({
        'isPublic': isPublic,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Impossibile aggiornare la privacy: $e");
    }
  }

  // 5. CAMBIA PASSWORD (BLINDATA)
  Future<void> sendPasswordReset() async {
    final user = currentUser;

    // Controllo base
    if (user == null || user.email == null) {
      throw Exception("Nessuna email associata a questo account.");
    }

    // CONTROLLO PROVIDER: Verifichiamo se l'utente usa Google
    // user.providerData contiene la lista dei metodi di accesso (google.com, password, ecc.)
    bool isGoogleUser = user.providerData.any(
      (userInfo) => userInfo.providerId == 'google.com',
    );

    if (isGoogleUser) {
      // Se è un utente Google, blocchiamo tutto e lanciamo un'eccezione specifica
      throw Exception(
        "Accedi con Google: non hai una password da cambiare. Gestisci la sicurezza tramite il tuo account Google.",
      );
    }

    try {
      // Se è un utente email/password, procediamo
      await _auth.sendPasswordResetEmail(email: user.email!);
    } on FirebaseAuthException catch (e) {
      // Gestione errori specifici di Firebase
      if (e.code == 'too-many-requests') {
        throw Exception("Troppe richieste. Riprova più tardi.");
      }
      throw Exception("Errore di sistema: ${e.message}");
    } catch (e) {
      throw Exception("Errore sconosciuto: $e");
    }
  }
}
