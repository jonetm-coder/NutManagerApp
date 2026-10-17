import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/services/basket_service.dart';

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

Future<List<ShoppingList>> _activeLists(AppDatabase database) {
  return (database.select(
    database.shoppingLists,
  )..where((row) => row.status.equalsValue(ShoppingListStatus.active))).get();
}

Future<List<ShoppingList>> _archivedLists(AppDatabase database) {
  return (database.select(database.shoppingLists)
        ..where((row) => row.status.equalsValue(ShoppingListStatus.archived))
        ..orderBy([(row) => OrderingTerm.desc(row.archivedAt)]))
      .get();
}

void main() {
  // LSTORG-1/LSTORG-2/LSTORG-3/LSTORG-4: multiple named lists, planned
  // items with quantity, and archiving — exercised directly against the
  // database/BasketService rather than through the screens that merely
  // issue these same queries.
  group('Shopping list organization', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      await _flushMicrotasks();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'creating a new named list adds it alongside the seeded one, both '
      'active (LSTORG-1)',
      () async {
        await database
            .into(database.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(
                name: 'Kroger',
                status: ShoppingListStatus.active,
              ),
            );

        final active = await _activeLists(database);

        expect(active.map((l) => l.name), containsAll(['My First List', 'Kroger']));
      },
    );

    test(
      'archiving a list removes it from the active set and adds it to the '
      'archived set with an archive timestamp (LSTORG-4), leaving other '
      'active lists untouched',
      () async {
        final keptActiveId = await database
            .into(database.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(
                name: 'Trader Joe\'s',
                status: ShoppingListStatus.active,
              ),
            );
        final toArchive = (await _activeLists(
          database,
        )).firstWhere((l) => l.name == 'My First List');

        await (database.update(
          database.shoppingLists,
        )..where((row) => row.id.equals(toArchive.id))).write(
          ShoppingListsCompanion(
            status: const Value(ShoppingListStatus.archived),
            archivedAt: Value(DateTime.now()),
          ),
        );

        final active = await _activeLists(database);
        final archived = await _archivedLists(database);

        expect(active.map((l) => l.id), [keptActiveId]);
        expect(archived.map((l) => l.name), ['My First List']);
        expect(archived.single.archivedAt, isNotNull);
      },
    );

    test(
      'a planned item added to a list defaults to quantity 1, and its '
      'quantity can be updated independently of a basket entry\'s own '
      'quantity (LSTORG-2, LSTORG-3)',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        final service = BasketService(database, seededList.id);
        await _flushMicrotasks();

        await service.addPlannedItem('Bananas');
        final planned = service.pendingItems.firstWhere(
          (item) => item.name == 'Bananas',
        );
        expect(planned.quantity, 1);

        await service.updateListItemQuantity(planned, 3);
        final updatedPlanned = service.listItems.firstWhere(
          (item) => item.id == planned.id,
        );
        expect(updatedPlanned.quantity, 3);

        await service.addManually('Bananas', matchedItem: updatedPlanned, quantity: 2);
        final basketEntry = service.basketEntries.singleWhere(
          (e) => e.productName == 'Bananas',
        );
        expect(basketEntry.quantity, 2);
        // The list item's planned quantity (3) is untouched by the basket
        // entry's actual quantity (2) — found fewer than planned.
        expect(
          service.listItems.firstWhere((i) => i.id == planned.id).quantity,
          3,
        );
      },
    );
  });
}
