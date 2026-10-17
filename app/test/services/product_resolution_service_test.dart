import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/services/barcode_lookup_service.dart';
import 'package:nut_manager_app/services/product_lookup_service.dart';
import 'package:nut_manager_app/services/product_resolution_service.dart';

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

/// A stand-in for the real external lookup, so these tests never touch the
/// network — [ProductResolutionService]'s third tier is exercised with a
/// canned answer instead.
class _FakeProductLookupService extends ProductLookupService {
  _FakeProductLookupService(this._result);

  final ExternalProductCandidate? _result;
  bool wasCalled = false;

  @override
  Future<ExternalProductCandidate?> lookupByBarcode(String barcode) async {
    wasCalled = true;
    return _result;
  }
}

void main() {
  // PLOOKUP-2: the three-tier waterfall (local catalog -> purchase history
  // -> external lookup) that backs "scan a product at home to add it."
  group('ProductResolutionService.resolve', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      await _flushMicrotasks();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'a barcode already in the local catalog resolves there and never '
      'reaches the external tier',
      () async {
        final fakeLookup = _FakeProductLookupService(null);
        final resolver = ProductResolutionService(
          database,
          BarcodeLookupService(database),
          fakeLookup,
        );

        final result = await resolver.resolve('100000000045');

        expect(result, isNotNull);
        expect(result!.name, 'Panko Bread Crumbs');
        expect(result.source, ResolutionSource.localCatalog);
        expect(fakeLookup.wasCalled, isFalse);
      },
    );

    test(
      'a barcode not in the catalog but seen in a past basket entry '
      'resolves via history and is promoted into the catalog',
      () async {
        final seededList = await database.select(database.shoppingLists).getSingle();
        await database
            .into(database.basketEntries)
            .insert(
              BasketEntriesCompanion.insert(
                listId: seededList.id,
                productName: 'Leftover Takeout Container',
                barcode: const Value('999000000001'),
              ),
            );
        final fakeLookup = _FakeProductLookupService(null);
        final resolver = ProductResolutionService(
          database,
          BarcodeLookupService(database),
          fakeLookup,
        );

        final result = await resolver.resolve('999000000001');

        expect(result, isNotNull);
        expect(result!.name, 'Leftover Takeout Container');
        expect(result.source, ResolutionSource.history);
        expect(fakeLookup.wasCalled, isFalse);

        final promoted = await BarcodeLookupService(
          database,
        ).lookup('999000000001');
        expect(promoted?.name, 'Leftover Takeout Container');
      },
    );

    test(
      'a barcode unknown locally falls through to the external lookup and '
      'is promoted into the catalog',
      () async {
        final fakeLookup = _FakeProductLookupService(
          const ExternalProductCandidate(
            barcode: '999000000002',
            name: 'Imported Olive Oil',
          ),
        );
        final resolver = ProductResolutionService(
          database,
          BarcodeLookupService(database),
          fakeLookup,
        );

        final result = await resolver.resolve('999000000002');

        expect(result, isNotNull);
        expect(result!.name, 'Imported Olive Oil');
        expect(result.source, ResolutionSource.external);
        expect(fakeLookup.wasCalled, isTrue);

        final promoted = await BarcodeLookupService(
          database,
        ).lookup('999000000002');
        expect(promoted?.name, 'Imported Olive Oil');
      },
    );

    test(
      'a barcode that misses all three tiers resolves to null (falls '
      'through to manual entry, same as SCAN-8)',
      () async {
        final fakeLookup = _FakeProductLookupService(null);
        final resolver = ProductResolutionService(
          database,
          BarcodeLookupService(database),
          fakeLookup,
        );

        final result = await resolver.resolve('999000000003');

        expect(result, isNull);
        expect(fakeLookup.wasCalled, isTrue);
      },
    );
  });
}
