import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/main.dart';

/// On-device coverage for the two Phase 1 manual test cases
/// (docs/test-plan.md) that don't involve the camera — MT1.5 and MT1.6.
/// These drive the real widget tree (the "+" button, the manual-add
/// dialog, and a basket entry's remove action), not just the service
/// layer already covered by test/services/basket_service_test.dart, so
/// this is checking UI wiring that those unit tests can't.
///
/// MT1.1-1.4 and MT1.7 genuinely need a real camera pointed at a real or
/// printed barcode and are not attempted here — per docs/test-plan.md,
/// Android emulators don't reliably simulate that.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MT1.6: manually adding an item shows it in the basket', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(NutManagerApp(database: database));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();

    // Deliberately not "Fresh Basil" or any other seeded list item name —
    // this needs a name with zero overlap with the seed list so the later
    // assertion isn't ambiguous (see the MT1.5 comment below for why that
    // matters).
    await tester.enterText(find.byType(TextField), 'Granola Bars');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Granola Bars'), findsOneWidget);
  });

  testWidgets(
    'MT1.6 regression: manually typing a lowercase name still matches an '
    'existing list item',
    (tester) async {
      // This is the exact scenario a real tester hit: scanning a real milk
      // carton (not one of the seed barcodes) fell through to manual
      // entry, and typing "milk" (lowercase) didn't match the list's
      // "Milk" item. The bug wasn't case-sensitivity — matching has always
      // lowercased both sides — it was that manual entry never attempted
      // to match the list at all. See manual_add_flow.dart.
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await tester.pumpWidget(NutManagerApp(database: database));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'milk');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // The basket entry keeps the exact text the user typed ("milk",
      // lowercase); the list item still displays its own seeded text
      // ("Milk"). The case difference conveniently makes the two
      // unambiguous to find, unlike the same-name case in MT1.5 below.
      expect(find.text('milk'), findsOneWidget); // the basket entry
      final checkbox = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Milk'),
      );
      expect(checkbox.value, isTrue);
    },
  );

  testWidgets(
    'MT1.5: removing a list-linked basket entry returns it to pending',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      // Set up a list-linked basket entry directly on the database,
      // standing in for a confident scan match (MT1.1-1.4's job, which
      // needs a real camera this emulator doesn't reliably provide) so
      // this test can focus on exercising the remove action itself.
      final pankoItem = await (database.select(
        database.shoppingListItems,
      )..where((row) => row.name.equals('Panko Bread Crumbs'))).getSingle();
      await database
          .into(database.basketEntries)
          .insert(
            BasketEntriesCompanion.insert(
              productName: pankoItem.name,
              listItemId: Value(pankoItem.id),
            ),
          );
      await (database.update(
        database.shoppingListItems,
      )..where((row) => row.id.equals(pankoItem.id))).write(
        const ShoppingListItemsCompanion(status: Value(ListItemStatus.found)),
      );

      await tester.pumpWidget(NutManagerApp(database: database));
      await tester.pumpAndSettle();

      // "Panko Bread Crumbs" now legitimately appears twice: once in the
      // shopping list (as a CheckboxListTile — which Flutter implements
      // internally using its own ListTile, so a ListTile-type finder
      // can't disambiguate the two) and once in the basket. Counting
      // Text matches avoids that and is the more accurate check anyway:
      // the point of a list-linked entry is that it shows in both places.
      expect(find.text('Panko Bread Crumbs'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Remove from basket'));
      await tester.pumpAndSettle();

      expect(find.text('Panko Bread Crumbs'), findsOneWidget);
      final checkbox = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Panko Bread Crumbs'),
      );
      expect(checkbox.value, isFalse);
    },
  );
}
