import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/AccountSetupPages/profile_setup_page.dart';
import 'package:library_ai/Pages/login_page.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/main.dart';
import 'package:library_ai/navigation_hub.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;

  setUp(() async {
    await sl.reset();
    authRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(authRepository);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows loading indicator while stream is waiting', (
    tester,
  ) async {
    final controller = StreamController<AppUser?>();
    when(() => authRepository.userStream).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await controller.close();
  });

  testWidgets('routes to ProfileSetupPage when displayName is empty', (
    tester,
  ) async {
    when(() => authRepository.userStream).thenAnswer(
      (_) => Stream.value(
        AppUser(id: 'u1', email: 'u1@mail.com', displayName: ''),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pump();

    expect(find.byType(ProfileSetupPage), findsOneWidget);
  });

  testWidgets('routes to NavigationHub when user has displayName', (
    tester,
  ) async {
    when(() => authRepository.userStream).thenAnswer(
      (_) => Stream.value(
        AppUser(id: 'u1', email: 'u1@mail.com', displayName: 'Mario'),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pump();

    expect(find.byType(NavigationHub), findsOneWidget);
  });

  testWidgets('routes to LoginPage when stream has no user', (tester) async {
    when(() => authRepository.userStream).thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('handles login -> logout -> login stream transitions', (
    tester,
  ) async {
    final controller = StreamController<AppUser?>();
    when(() => authRepository.userStream).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(const MaterialApp(home: AuthGate()));

    controller.add(
      AppUser(id: 'u1', email: 'u1@mail.com', displayName: 'Mario'),
    );
    await tester.pump();
    expect(find.byType(NavigationHub), findsOneWidget);

    controller.add(null);
    await tester.pump();
    expect(find.byType(LoginPage), findsOneWidget);

    controller.add(
      AppUser(id: 'u2', email: 'u2@mail.com', displayName: 'Anna'),
    );
    await tester.pump();
    expect(find.byType(NavigationHub), findsOneWidget);

    await controller.close();
  });
}
