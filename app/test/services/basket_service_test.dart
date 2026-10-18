import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/services/basket_service.dart';
import 'package:nut_manager_app/services/product_lookup_service.dart';

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

/// Returns no candidates — keeps [BasketService.addPlannedItem]'s
/// background barcode lookup (PLOOKUP-3) from making a real network call
/// during these tests.
class _FakeProductLookupService extends ProductLookupService {
  @override
  Future<List<ExternalProductCandidate>> searchByName(
    String name, {
    int limit = 10,
  }) async => const [];
}

void main() {
  // AT1.5: basket state transitions — add via scan, add manually, remove
  // (with the list item reverting to pending).
  group('BasketService', () {
    late AppDatabase database;
    late BasketService service;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      // The seed data is inserted asynchronously in AppDatabase's onCreate;
      // let that finish before reading the seeded list's id.
      await _flushMicrotasks();
      final seededList = await database.select(database.shoppingLists).getSingle();
      service = BasketService(
        database,
        seededList.id,
        productLookup: _FakeProductLookupService(),
      );
      // Likewise for the service's own constructor-triggered reload.
      await _flushMicrotasks();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'adding a scanned product matched to a list item marks it found',
      () async {
        final panko = await (database.select(
          database.catalogEntries,
        )..where((row) => row.barcode.equals('100000000045'))).getSingle();
        final pankoItem = service.pendingItems.firstWhere(
          (item) => item.name == 'Panko Bread Crumbs',
        );

        await service.addFromMatch(
          product: panko,
          matchedItem: pankoItem,
        );

        expect(
          service.basketEntries.map((e) => e.productName),
          contains('Panko Bread Crumbs'),
        );
        expect(
          service.listItems.firstWhere((i) => i.id == pankoItem.id).status,
          ListItemStatus.found,
        );
        expect(
          service.pendingItems.any((i) => i.id == pankoItem.id),
          isFalse,
        );
      },
    );

    test(
      'adding a scanned product with no list match still adds to the basket',
      () async {
        final onion = await (database.select(
          database.catalogEntries,
        )..where((row) => row.barcode.equals('100000000106'))).getSingle();

        await service.addFromMatch(product: onion, matchedItem: null);

        final entry = service.basketEntries.singleWhere(
          (e) => e.productName == 'Yellow Onion',
        );
        expect(entry.listItemId, isNull);
      },
    );

    test(
      'manual add creates a basket entry not linked to any list item (LIST-5)',
      () async {
        await service.addManually('Fresh Basil');

        final entry = service.basketEntries.singleWhere(
          (e) => e.productName == 'Fresh Basil',
        );
        expect(entry.listItemId, isNull);
        expect(entry.barcode, isNull);
      },
    );

    test(
      'manual add with a matched item links it and marks the list item '
      'found, same as a scanned match — regression test for the bug where '
      'manual entry never attempted to match the list at all',
      () async {
        final pankoItem = service.pendingItems.firstWhere(
          (item) => item.name == 'Panko Bread Crumbs',
        );

        await service.addManually('panko bread crumbs', matchedItem: pankoItem);

        final entry = service.basketEntries.singleWhere(
          (e) => e.productName == 'panko bread crumbs',
        );
        expect(entry.listItemId, pankoItem.id);
        expect(entry.barcode, isNull);
        expect(
          service.listItems.firstWhere((i) => i.id == pankoItem.id).status,
          ListItemStatus.found,
        );
      },
    );

    test('removing a list-linked basket entry returns the item to pending (LIST-4)', () async {
      final panko = await (database.select(
        database.catalogEntries,
      )..where((row) => row.barcode.equals('100000000045'))).getSingle();
      final pankoItem = service.pendingItems.firstWhere(
        (item) => item.name == 'Panko Bread Crumbs',
      );
      await service.addFromMatch(product: panko, matchedItem: pankoItem);
      final entry = service.basketEntries.singleWhere(
        (e) => e.productName == 'Panko Bread Crumbs',
      );

      await service.remove(entry);

      expect(service.basketEntries.any((e) => e.id == entry.id), isFalse);
      expect(
        service.listItems.firstWhere((i) => i.id == pankoItem.id).status,
        ListItemStatus.pending,
      );
    });

    test(
      'removing a manually-added entry does not touch any list item',
      () async {
        await service.addManually('Fresh Basil');
        final entry = service.basketEntries.singleWhere(
          (e) => e.productName == 'Fresh Basil',
        );
        final listItemCountBefore = service.listItems.length;

        await service.remove(entry);

        expect(service.basketEntries.any((e) => e.id == entry.id), isFalse);
        expect(service.listItems.length, listItemCountBefore);
      },
    );
  });
}
