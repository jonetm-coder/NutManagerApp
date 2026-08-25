import 'package:drift/drift.dart';

/// Whether a shopping list item has been found/purchased yet.
///
/// UREQS: LIST-2, LIST-4
enum ListItemStatus {
  /// Not yet matched to a scanned/manually-added basket entry.
  pending,

  /// Matched to a basket entry.
  found,
}

/// The local product catalog (Phase 1: a small hand-picked seed dataset,
/// per [docs/development-plan.md] Phase 1 — this will become the synced
/// subset of the shared barcode/nutrition databases from ADR 0012/ADR 0013
/// in a later phase).
///
/// UREQS: SCAN-1, SYNC-1
class CatalogEntries extends Table {
  /// The decoded barcode value, used as the primary lookup key.
  ///
  /// UREQS: SCAN-1
  TextColumn get barcode => text()();

  /// Human-readable product name.
  ///
  /// UREQS: SCAN-1
  TextColumn get name => text()();

  /// A coarse category used by the matching engine's synonym/category
  /// fallback (LIST-6).
  ///
  /// UREQS: LIST-6
  TextColumn get category => text()();

  @override
  Set<Column> get primaryKey => {barcode};
}

/// A single item on the household's shopping list.
///
/// UREQS: LIST-2, SYNC-1
class ShoppingListItems extends Table {
  /// Row identifier.
  ///
  /// UREQS: LIST-2
  IntColumn get id => integer().autoIncrement()();

  /// The list item's text as entered/generated (e.g., "Milk").
  ///
  /// UREQS: LIST-2, LIST-6
  TextColumn get name => text()();

  /// Coarse category, used the same way as [CatalogEntries.category].
  ///
  /// UREQS: LIST-6
  TextColumn get category => text()();

  /// Whether this item has been matched to a basket entry yet.
  ///
  /// UREQS: LIST-2, LIST-4
  TextColumn get status => textEnum<ListItemStatus>()();
}

/// An item that has been added to the shopping basket, either by scanning a
/// product that matched a list item, or by manual entry.
///
/// UREQS: LIST-4, LIST-5
class BasketEntries extends Table {
  /// Row identifier.
  ///
  /// UREQS: LIST-4
  IntColumn get id => integer().autoIncrement()();

  /// The shopping list item this entry fulfills, if any. `null` for a
  /// manually-added item with no corresponding list entry.
  ///
  /// UREQS: LIST-2, LIST-5
  IntColumn get listItemId =>
      integer().nullable().references(ShoppingListItems, #id)();

  /// The product/item name shown in the basket.
  ///
  /// UREQS: LIST-2, LIST-5
  TextColumn get productName => text()();

  /// The barcode that was scanned to produce this entry, if any. `null` for
  /// a manually-added item.
  ///
  /// UREQS: SCAN-1, LIST-5
  TextColumn get barcode => text().nullable()();

  /// When this entry was added.
  ///
  /// UREQS: LIST-4
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}
