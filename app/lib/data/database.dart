import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'seed_catalog.dart';
import 'tables.dart';

export 'seed_catalog.dart';
export 'tables.dart';

part 'database.g.dart';

/// The app's local database (SYNC-1): the product catalog seed data,
/// shopping lists and their items, and baskets.
///
/// Phase 1 is local-only — this is not yet synced with any cloud backend
/// (that's Phase 2, per docs/development-plan.md).
///
/// UREQS: SYNC-1
@DriftDatabase(
  tables: [CatalogEntries, ShoppingLists, ShoppingListItems, BasketEntries],
)
class AppDatabase extends _$AppDatabase {
  /// Creates the database. Pass [executor] to use an in-memory or otherwise
  /// custom connection (e.g., in tests); omit it to use the real on-device
  /// file database.
  ///
  /// UREQS: SYNC-1
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Bumped from 1 to add ShoppingLists (LSTORG-1) and the listId/quantity/
  // price columns. There's no real deployed user data yet — only local
  // dev/test data, and testers already know to clear app storage when the
  // schema changes (see docs/test-plan.md) — so this is a destructive
  // recreate-and-reseed rather than a column-preserving migration. Revisit
  // this approach once there's real data worth preserving across upgrades.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seed();
    },
    onUpgrade: (migrator, from, to) async {
      for (final table in allTables) {
        await migrator.deleteTable(table.actualTableName);
      }
      await migrator.createAll();
      await _seed();
    },
  );

  Future<void> _seed() async {
    final listId = await into(shoppingLists).insert(
      ShoppingListsCompanion.insert(
        name: 'My First List',
        status: ShoppingListStatus.active,
      ),
    );
    await batch((b) {
      b.insertAll(catalogEntries, seedCatalog);
      b.insertAll(shoppingListItems, seedShoppingListItems(listId));
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'nut_manager.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
