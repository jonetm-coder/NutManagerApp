import 'package:drift/drift.dart' show OrderingTerm, Value;
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

/// Returns one fixed candidate for any search — used to verify a found
/// candidate actually gets cached into the local catalog.
class _StubProductLookupService extends ProductLookupService {
  _StubProductLookupService(this._candidate);

  final ExternalProductCandidate _candidate;
  final List<String> searchedNames = [];
  final List<int> receivedLimits = [];

  @override
  Future<List<ExternalProductCandidate>> searchByName(
    String name, {
    int limit = 10,
  }) async {
    searchedNames.add(name);
    receivedLimits.add(limit);
    return [_candidate];
  }
}

/// Returns several candidates spanning different brands for any search —
/// used to verify brand-agnostic breadth: every candidate returned gets
/// cached, not just one "best" guess.
class _MultiCandidateProductLookupService extends ProductLookupService {
  _MultiCandidateProductLookupService(this._candidates);

  final List<ExternalProductCandidate> _candidates;

  @override
  Future<List<ExternalProductCandidate>> searchByName(
    String name, {
    int limit = 10,
  }) async => _candidates;
}

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
        final service = BasketService(
          database,
          seededList.id,
          productLookup: _FakeProductLookupService(),
        );
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

    test(
      'adding a planned item looks up and caches a candidate barcode into '
      'the local catalog in the background, so a later in-store scan of '
      'the real product can resolve purely offline (PLOOKUP-3) — the fix '
      'for the bug where the in-list Scan button never found a real '
      'product because nothing had ever populated the local catalog for it',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        final stubLookup = _StubProductLookupService(
          const ExternalProductCandidate(
            barcode: '0048121102081',
            name: "Thomas's English Muffins",
          ),
        );
        final service = BasketService(
          database,
          seededList.id,
          productLookup: stubLookup,
        );
        await _flushMicrotasks();

        await service.addPlannedItem(
          "Thomas's English Mufins",
          category: 'bakery',
        );
        // addPlannedItem fires the lookup unawaited; give it a chance to
        // complete before asserting on its side effect.
        await _flushMicrotasks();

        expect(stubLookup.searchedNames, ["Thomas's English Mufins"]);
        final cached = await (database.select(
          database.catalogEntries,
        )..where((row) => row.barcode.equals('0048121102081'))).getSingleOrNull();
        expect(cached?.name, "Thomas's English Muffins");
        expect(cached?.category, 'bakery');
      },
    );

    test(
      'lookUpAndCacheBarcodes (the "Check Products" action) returns how '
      'many candidates were found across all items passed to it',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        final stubLookup = _StubProductLookupService(
          const ExternalProductCandidate(barcode: '000000000001', name: 'Milk'),
        );
        final service = BasketService(
          database,
          seededList.id,
          productLookup: stubLookup,
        );
        await _flushMicrotasks();

        final foundCount = await service.lookUpAndCacheBarcodes([
          (name: 'Milk', category: 'dairy'),
          (name: 'Eggs', category: 'dairy'),
        ]);

        expect(foundCount, 2);
        expect(stubLookup.searchedNames, ['Milk', 'Eggs']);
      },
    );

    test(
      'searches with a higher-than-default limit, so a vague item name '
      'like "English Muffins" has a better chance of surfacing the '
      'specific SKU the user actually owns among many similarly-named '
      'products',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        final stubLookup = _StubProductLookupService(
          const ExternalProductCandidate(barcode: '000000000001', name: 'Milk'),
        );
        final service = BasketService(
          database,
          seededList.id,
          productLookup: stubLookup,
        );
        await _flushMicrotasks();

        await service.lookUpAndCacheBarcodes([(name: 'Milk', category: 'dairy')]);

        expect(stubLookup.receivedLimits.single, greaterThan(10));
      },
    );

    test(
      'caches every candidate a search returns, regardless of brand — not '
      'just the first/top-ranked one, since there is no way to know ahead '
      'of time which brand/SKU the user actually has on their list',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        final multiLookup = _MultiCandidateProductLookupService(const [
          ExternalProductCandidate(barcode: '0048121102081', name: 'Thomas Original'),
          ExternalProductCandidate(barcode: '0048121184711', name: 'Thomas Hearty'),
          ExternalProductCandidate(
            barcode: '0099482474843',
            name: 'Whole Foods Whole Wheat Muffins',
          ),
        ]);
        final service = BasketService(
          database,
          seededList.id,
          productLookup: multiLookup,
        );
        await _flushMicrotasks();

        final foundCount = await service.lookUpAndCacheBarcodes([
          (name: 'English Muffins', category: 'bakery'),
        ]);

        expect(foundCount, 3);
        final cachedBarcodes = (await database.select(database.catalogEntries).get())
            .map((e) => e.barcode)
            .toSet();
        expect(
          cachedBarcodes,
          containsAll(['0048121102081', '0048121184711', '0099482474843']),
        );
      },
    );

    test(
      'cacheExternalBarcodeMatch (the scan-time live-lookup fallback, '
      'SCAN-11) writes a specific barcode->product match into the local '
      'catalog',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        final service = BasketService(
          database,
          seededList.id,
          productLookup: _FakeProductLookupService(),
        );
        await _flushMicrotasks();

        await service.cacheExternalBarcodeMatch(
          '048121184117',
          name: 'Original English Muffins',
          category: 'bakery',
        );

        final cached = await (database.select(
          database.catalogEntries,
        )..where((row) => row.barcode.equals('048121184117'))).getSingleOrNull();
        expect(cached?.name, 'Original English Muffins');
        expect(cached?.category, 'bakery');
      },
    );

    test(
      'a past purchase (any list, active or archived) whose name plausibly '
      'matches a new item is cached by its exact historical barcode, '
      'before the external search even runs — a person buying the same '
      'product again should resolve it with zero network calls',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        final archivedList = await database
            .into(database.shoppingLists)
            .insert(
              ShoppingListsCompanion.insert(
                name: 'Old Trip',
                status: ShoppingListStatus.archived,
              ),
            );
        await database
            .into(database.basketEntries)
            .insert(
              BasketEntriesCompanion.insert(
                listId: archivedList,
                productName: 'Original English Muffins',
                barcode: const Value('048121184117'),
              ),
            );
        final fakeExternal = _FakeProductLookupService();
        final service = BasketService(
          database,
          seededList.id,
          productLookup: fakeExternal,
        );
        await _flushMicrotasks();

        final foundCount = await service.lookUpAndCacheBarcodes([
          (name: "Thomas's English Mufins", category: 'bakery'),
        ]);

        expect(foundCount, 1);
        final cached = await (database.select(
          database.catalogEntries,
        )..where((row) => row.barcode.equals('048121184117'))).getSingleOrNull();
        expect(cached?.name, 'Original English Muffins');
        expect(cached?.category, 'bakery');
      },
    );

    test(
      'a past purchase with no plausible name relationship to the new '
      'item is not cached as a false match',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        await database
            .into(database.basketEntries)
            .insert(
              BasketEntriesCompanion.insert(
                listId: seededList.id,
                productName: 'Frozen Pizza',
                barcode: const Value('000111222333'),
              ),
            );
        final service = BasketService(
          database,
          seededList.id,
          productLookup: _FakeProductLookupService(),
        );
        await _flushMicrotasks();

        final foundCount = await service.lookUpAndCacheBarcodes([
          (name: 'Orange Juice', category: 'beverages'),
        ]);

        expect(foundCount, 0);
        final cached = await (database.select(
          database.catalogEntries,
        )..where((row) => row.barcode.equals('000111222333'))).getSingleOrNull();
        expect(cached, isNull);
      },
    );

    test(
      'adding a planned item also checks history first, via the same '
      'background lookup as the external search (PLOOKUP-3)',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        await database
            .into(database.basketEntries)
            .insert(
              BasketEntriesCompanion.insert(
                listId: seededList.id,
                productName: 'Original English Muffins',
                barcode: const Value('048121184117'),
              ),
            );
        final service = BasketService(
          database,
          seededList.id,
          productLookup: _FakeProductLookupService(),
        );
        await _flushMicrotasks();

        await service.addPlannedItem(
          "Thomas's English Mufins",
          category: 'bakery',
        );
        await _flushMicrotasks();

        final cached = await (database.select(
          database.catalogEntries,
        )..where((row) => row.barcode.equals('048121184117'))).getSingleOrNull();
        expect(cached?.name, 'Original English Muffins');
      },
    );
  });
}
