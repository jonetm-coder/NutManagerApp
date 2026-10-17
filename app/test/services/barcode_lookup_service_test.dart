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
  });
}
