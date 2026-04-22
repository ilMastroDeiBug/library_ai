import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:library_ai/data/supabase_auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'dart:async';

class MockSupabaseClient extends Mock implements supa.SupabaseClient {}

class MockGoTrueClient extends Mock implements supa.GoTrueClient {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}
// Assicurati di avere questo import per FutureOr

// --- IL FAKE PER INGANNARE SUPABASE RPC ---
class FakePostgrestFilterBuilder extends Fake
    implements supa.PostgrestFilterBuilder<dynamic> {
  final Future<dynamic> _future = Future.value(null);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<dynamic> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return _future.whenComplete(action);
  }

  @override
  Stream<dynamic> asStream() => _future.asStream();

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }
}

void main() {
  late MockSupabaseClient supabase;
  late MockGoTrueClient auth;
  late MockGoogleSignIn googleSignIn;
  late SupabaseAuthRepositoryImpl repository;

  setUp(() {
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    googleSignIn = MockGoogleSignIn();

    when(() => supabase.auth).thenReturn(auth);
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => const Stream<supa.AuthState>.empty());
    when(() => auth.currentUser).thenReturn(null);

    repository = SupabaseAuthRepositoryImpl(
      supabaseClient: supabase,
      googleSignIn: googleSignIn,
    );
  });

  group('SupabaseAuthRepositoryImpl critical flows', () {
    test('signInWithGoogle throws when user cancels', () async {
      when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => googleSignIn.signIn()).thenAnswer((_) async => null);

      await expectLater(repository.signInWithGoogle(), throwsException);

      verify(() => googleSignIn.signOut()).called(1);
      verify(() => googleSignIn.signIn()).called(1);
      verifyNever(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      );
    });

    test('signInWithGoogle throws when tokens are null', () async {
      final account = MockGoogleSignInAccount();
      final authData = MockGoogleSignInAuthentication();

      when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
      when(() => account.authentication).thenAnswer((_) async => authData);
      when(() => authData.accessToken).thenReturn(null);
      when(() => authData.idToken).thenReturn(null);

      await expectLater(repository.signInWithGoogle(), throwsException);

      verify(() => googleSignIn.signIn()).called(1);
      verifyNever(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      );
    });

    test('signInWithGoogle calls signInWithIdToken on valid tokens', () async {
      final account = MockGoogleSignInAccount();
      final authData = MockGoogleSignInAuthentication();

      when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
      when(() => account.authentication).thenAnswer((_) async => authData);
      when(() => authData.accessToken).thenReturn('acc-token');
      when(() => authData.idToken).thenReturn('id-token');
      when(
        () => auth.signInWithIdToken(
          provider: supa.OAuthProvider.google,
          idToken: 'id-token',
          accessToken: 'acc-token',
        ),
      ).thenAnswer((_) async => supa.AuthResponse());

      await repository.signInWithGoogle();

      verify(
        () => auth.signInWithIdToken(
          provider: supa.OAuthProvider.google,
          idToken: 'id-token',
          accessToken: 'acc-token',
        ),
      ).called(1);
    });

    test('logout signs out from google and supabase auth', () async {
      when(() => googleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => auth.signOut()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => googleSignIn.signOut()).called(1);
      verify(() => auth.signOut()).called(1);
    });

    test('deleteAccount runs rpc then signOut', () async {
      // SOSTITUISCI IL THEN_ANSWER CON IL NOSTRO FAKE BUILDER
      when(
        () => supabase.rpc('delete_user'),
      ).thenReturn(FakePostgrestFilterBuilder());

      when(() => auth.signOut()).thenAnswer((_) async {});

      await repository.deleteAccount();

      verify(() => supabase.rpc('delete_user')).called(1);
      verify(() => auth.signOut()).called(1);
    });
  });
}
