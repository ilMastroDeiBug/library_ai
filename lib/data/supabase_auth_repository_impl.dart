import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';

class SupabaseAuthRepositoryImpl implements AuthRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  // Converte l'utente Auth di Supabase nella tua Entity AppUser
  AppUser? _mapUser(supa.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id, // <-- CORRETTO: Ora usa 'id' come vuole la tua classe
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
    throw UnimplementedError(
      "Login Google su Supabase: Lo facciamo al prossimo step!",
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
