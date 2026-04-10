import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:google_sign_in/google_sign_in.dart'; // <-- AGGIUNTO L'IMPORT PER GOOGLE
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  // Converte l'utente Auth di Supabase nella tua Entity AppUser
  AppUser? _mapUser(supa.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['name'] ?? 'Utente',
      // 'bio' e 'isPublic' prendono i default finché non li scarichiamo dal database
    );
  }

  @override
  Stream<AppUser?> get userStream {
    return _supabase.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user),
    );
  }

  @override
  AppUser? get currentUser => _mapUser(_supabase.auth.currentUser);

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> register(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    // 1. IL TUO WEB CLIENT ID (Prende il posto dell'eccezione)
    const webClientId =
        '474613371614-gjgpn9354i52qo7msde01vuq2s54k2d2.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);

    // 2. Apriamo il popup per far scegliere l'account
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Login con Google annullato.');
    }

    // 3. Estraiamo i gettoni di sicurezza (Token)
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Impossibile ottenere i token di accesso da Google.');
    }

    // 4. Autentichiamo su Supabase
    await _supabase.auth.signInWithIdToken(
      provider: supa.OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _supabase.auth.updateUser(supa.UserAttributes(data: {'name': name}));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
