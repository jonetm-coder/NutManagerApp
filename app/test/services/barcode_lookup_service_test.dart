import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/services/barcode_lookup_service.dart';

void main() {
  // AT1.1: pure barcode->Product lookup logic, no camera/image involved.
  group('BarcodeLookupService', () {
    late AppDatabase database;
    late BarcodeLookupService service;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      service = BarcodeLookupService(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('resolves a known seeded barcode to the correct product', () async {
      final result = await service.lookup('100000000045');
      expect(result, isNotNull);
      expect(result!.name, 'Panko Bread Crumbs');
    });

    test('returns null for a barcode not in the catalog', () async {
      final result = await service.lookup('999999999999');
      expect(result, isNull);
    });

    test('returns null for an empty barcode without throwing', () async {
      final result = await service.lookup('');
      expect(result, isNull);
    });

    // Regression test: a real product's barcode was cached via
    // ProductLookupService (which stores whatever digit-length Open Food
    // Facts' `code` field returns, often 13-digit EAN-13) but ML Kit scans
    // a printed UPC-A code as 12 digits — a literal string-equality
    // lookup silently missed, even though a candidate genuinely was in
    // the catalog.
    test(
      'a 13-digit catalog entry (as Open Food Facts stores UPC-A codes) '
      'is found by a 12-digit scanned UPC-A code',
      () async {
        await database
            .into(database.catalogEntries)
            .insert(
              CatalogEntriesCompanion.insert(
                barcode: '0048121102081',
                name: "Thomas's English Muffins",
                category: 'bakery',
              ),
            );

        final result = await service.lookup('048121102081');

        expect(result?.name, "Thomas's English Muffins");
      },
    );

    test(
      'a 12-digit catalog entry is found by a 13-digit zero-padded scan',
      () async {
        await database
            .into(database.catalogEntries)
            .insert(
              CatalogEntriesCompanion.insert(
                barcode: '048121102081',
                name: 'Some Product',
                category: 'other',
              ),
            );

        final result = await service.lookup('0048121102081');

        expect(result?.name, 'Some Product');
      },
    );

    test(
      'if both digit-length forms somehow exist as separate catalog rows, '
      'lookup still returns a match rather than throwing',
      () async {
        await database
            .into(database.catalogEntries)
            .insert(
              CatalogEntriesCompanion.insert(
                barcode: '048121102081',
                name: 'Twelve Digit Row',
                category: 'other',
              ),
            );
        await database
            .into(database.catalogEntries)
            .insert(
              CatalogEntriesCompanion.insert(
                barcode: '0048121102081',
                name: 'Thirteen Digit Row',
                category: 'other',
              ),
            );

        final result = await service.lookup('048121102081');

        expect(result, isNotNull);
      },
    );
  });

  group('BarcodeLookupService.variantsOf', () {
    test('a 12-digit code gains its zero-padded 13-digit form', () {
      expect(
        BarcodeLookupService.variantsOf('048121102081'),
        {'048121102081', '0048121102081'},
      );
    });

    test('a 13-digit code starting with 0 gains its 12-digit form', () {
      expect(
        BarcodeLookupService.variantsOf('0048121102081'),
        {'0048121102081', '048121102081'},
      );
    });

    test('a 13-digit code not starting with 0 is left as-is', () {
      expect(
        BarcodeLookupService.variantsOf('4006381333931'),
        {'4006381333931'},
      );
    });
  });
}
