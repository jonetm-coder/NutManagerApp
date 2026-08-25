import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';

void main() {
  // AT1.6: the local cache (SYNC-1) persists the seeded catalog/list across
  // an app restart — modeled here as closing and reopening the database
  // against the same file, with no network involved at any point.
  group('AppDatabase persistence', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('nut_manager_db_test');
      dbFile = File('${tempDir.path}/test.sqlite');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('seed catalog and list are present on first creation', () async {
      final database = AppDatabase(NativeDatabase(dbFile));

      final catalog = await database.select(database.catalogEntries).get();
      final list = await database.select(database.shoppingListItems).get();

      expect(catalog, hasLength(12));
      expect(list, hasLength(4));

      await database.close();
    });

    test('reopening the same file does not lose or duplicate data', () async {
      final first = AppDatabase(NativeDatabase(dbFile));
      await first.select(first.catalogEntries).get();
      await first.close();

      final second = AppDatabase(NativeDatabase(dbFile));
      final catalog = await second.select(second.catalogEntries).get();
      final list = await second.select(second.shoppingListItems).get();

      // Still exactly the seeded amount — reopening must not re-seed.
      expect(catalog, hasLength(12));
      expect(list, hasLength(4));

      await second.close();
    });

    test(
      'a change made before closing is still there after reopening',
      () async {
        final first = AppDatabase(NativeDatabase(dbFile));
        final item = (await first.select(first.shoppingListItems).get()).first;
        await (first.update(
          first.shoppingListItems,
        )..where((row) => row.id.equals(item.id))).write(
          const ShoppingListItemsCompanion(status: Value(ListItemStatus.found)),
        );
        await first.close();

        final second = AppDatabase(NativeDatabase(dbFile));
        final reloaded = await (second.select(
          second.shoppingListItems,
        )..where((row) => row.id.equals(item.id))).getSingle();
        expect(reloaded.status, ListItemStatus.found);

        await second.close();
      },
    );
  });
}
