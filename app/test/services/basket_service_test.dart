import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/services/basket_service.dart';

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  // AT1.5: basket state transitions — add via scan, add manually, remove
  // (with the list item reverting to pending).
  group('BasketService', () {
    late AppDatabase database;
    late BasketService service;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      service = BasketService(database);
      // The seed data is inserted asynchronously in AppDatabase's onCreate;
      // let that finish before each test starts.
      await _flushMicrotasks();
    });

    tearDown(() async {
      await database.close();
    });

    test('adding a scanned product matched to a list item marks it found', () async {
      final cheerios = await (database.select(
        database.catalogEntries,
      )..where((row) => row.barcode.equals('100000000004'))).getSingle();
      final cheeriosItem = service.pendingItems.firstWhere(
        (item) => item.name == 'Cheerios Cereal',
      );

      await service.addFromMatch(product: cheerios, matchedItem: cheeriosItem);

      expect(service.basketEntries.map((e) => e.productName), contains('Cheerios Cereal'));
      expect(
        service.listItems.firstWhere((i) => i.id == cheeriosItem.id).status,
        ListItemStatus.found,
      );
      expect(service.pendingItems.any((i) => i.id == cheeriosItem.id), isFalse);
    });

    test('adding a scanned product with no list match still adds to the basket', () async {
      final onion = await (database.select(
        database.catalogEntries,
      )..where((row) => row.barcode.equals('100000000010'))).getSingle();

      await service.addFromMatch(product: onion, matchedItem: null);

      final entry = service.basketEntries.singleWhere((e) => e.productName == 'Yellow Onion');
      expect(entry.listItemId, isNull);
    });

    test('manual add creates a basket entry not linked to any list item (LIST-5)', () async {
      await service.addManually('Fresh Basil');

      final entry = service.basketEntries.singleWhere((e) => e.productName == 'Fresh Basil');
      expect(entry.listItemId, isNull);
      expect(entry.barcode, isNull);
    });

    test('removing a list-linked basket entry returns the item to pending (LIST-4)', () async {
      final cheerios = await (database.select(
        database.catalogEntries,
      )..where((row) => row.barcode.equals('100000000004'))).getSingle();
      final cheeriosItem = service.pendingItems.firstWhere(
        (item) => item.name == 'Cheerios Cereal',
      );
      await service.addFromMatch(product: cheerios, matchedItem: cheeriosItem);
      final entry = service.basketEntries.singleWhere((e) => e.productName == 'Cheerios Cereal');

      await service.remove(entry);

      expect(service.basketEntries.any((e) => e.id == entry.id), isFalse);
      expect(
        service.listItems.firstWhere((i) => i.id == cheeriosItem.id).status,
        ListItemStatus.pending,
      );
    });

    test('removing a manually-added entry does not touch any list item', () async {
      await service.addManually('Fresh Basil');
      final entry = service.basketEntries.singleWhere((e) => e.productName == 'Fresh Basil');
      final listItemCountBefore = service.listItems.length;

      await service.remove(entry);

      expect(service.basketEntries.any((e) => e.id == entry.id), isFalse);
      expect(service.listItems.length, listItemCountBefore);
    });
  });
}
