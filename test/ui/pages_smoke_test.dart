import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/models/app_mode.dart';
import 'package:library_ai/pages/home_page.dart';

void main() {
  group('HomePage UI smoke tests', () {
    testWidgets('books mode renders coming-soon CTA and reacts to tap', (
      tester,
    ) async {
      var drawerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            mode: AppMode.books,
            onOpenDrawer: () => drawerTapped = true,
          ),
        ),
      );

      expect(find.text('Il Vault Definitivo'), findsOneWidget);
      expect(find.text('Avvisami al rilascio'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump();
      expect(drawerTapped, isTrue);

      await tester.tap(find.text('Avvisami al rilascio'));
      await tester.pump();

      expect(find.textContaining('Grazie! Ti avviseremo'), findsOneWidget);
    });

    testWidgets('movies mode renders switcher and search icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(mode: AppMode.movies, onOpenDrawer: () {}),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Film'), findsOneWidget);
      expect(find.text('Serie TV'), findsOneWidget);
    });
  });
}
