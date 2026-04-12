import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  AppUser? _mapUser(supa.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['name'] ?? 'Utente',
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
    const webClientId =
        '474613371614-gjgpn9354i52qo7msde01vuq2s54k2d2.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);

    // FIX GOOGLE: Sloggiamo localmente prima di iniziare.
    // Forza Google a mostrare sempre la tendina di scelta account!
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Login annullato.');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Impossibile ottenere i token di accesso da Google.');
    }

    await _supabase.auth.signInWithIdToken(
      provider: supa.OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> logout() async {
    await GoogleSignIn().signOut(); // Sloggiamo anche da Google
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

  @override
  Future<void> deleteAccount() async {
    await _supabase.rpc('delete_user');
    await _supabase.auth.signOut();
  }
}
