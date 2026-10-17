import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/screens/shopping_lists_home_screen.dart';

void main() {
  // LSTORG-1/LSTORG-4: the active-lists view must reflect a create or
  // archive immediately, without requiring the screen to be torn down and
  // rebuilt — regression test for a bug where `setState(() => _activeLists
  // = _loadActiveLists())`'s arrow-function body evaluated to the
  // assignment's Future value, which Flutter's setState() rejects as "a
  // callback that returned a Future" and silently skips the rebuild for,
  // leaving the list visibly stale even though the underlying database
  // write had already succeeded.
  group('ShoppingListsHomeScreen refresh', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets(
      'creating a new list shows it on screen without navigating away',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ShoppingListsHomeScreen(database: database)),
        );
        await tester.pumpAndSettle();
        expect(find.text('My First List'), findsOneWidget);
        expect(find.text('Kroger'), findsNothing);

        await tester.tap(find.byTooltip('New list'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Kroger');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Kroger'), findsOneWidget);
        expect(find.text('My First List'), findsOneWidget);
      },
    );

    testWidgets(
      'archiving the open list removes it from the active view on return',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: ShoppingListsHomeScreen(database: database)),
        );
        await tester.pumpAndSettle();
        expect(find.text('My First List'), findsOneWidget);

        await tester.tap(find.text('My First List'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Archive this list'));
        await tester.pumpAndSettle();

        expect(find.text('My First List'), findsNothing);
        expect(find.text('No shopping lists yet.'), findsOneWidget);
      },
    );
  });
}
