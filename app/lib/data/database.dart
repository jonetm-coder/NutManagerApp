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

/// The app's local database (SYNC-1): the Phase 1 product catalog seed
/// data, the shopping list, and the basket.
///
/// Phase 1 is local-only — this is not yet synced with any cloud backend
/// (that's Phase 2, per docs/development-plan.md).
///
/// UREQS: SYNC-1
@DriftDatabase(tables: [CatalogEntries, ShoppingListItems, BasketEntries])
class AppDatabase extends _$AppDatabase {
  /// Creates the database. Pass [executor] to use an in-memory or otherwise
  /// custom connection (e.g., in tests); omit it to use the real on-device
  /// file database.
  ///
  /// UREQS: SYNC-1
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seed();
    },
  );

  Future<void> _seed() async {
    await batch((b) {
      b.insertAll(catalogEntries, seedCatalog);
      b.insertAll(shoppingListItems, seedShoppingList);
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
