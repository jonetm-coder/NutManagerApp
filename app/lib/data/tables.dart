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

/// Whether a shopping list is still being actively shopped, or has been
/// filed away once the trip is done.
///
/// UREQS: LSTORG-3, LSTORG-4
enum ShoppingListStatus {
  /// The list the user is currently planning or shopping with.
  active,

  /// A completed trip, kept for history but no longer edited day to day.
  archived,
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

/// A named shopping list — typically one per store the household plans to
/// shop at.
///
/// UREQS: LSTORG-1, LSTORG-3, LSTORG-4, LSTORG-5
class ShoppingLists extends Table {
  /// Row identifier.
  ///
  /// UREQS: LSTORG-1
  IntColumn get id => integer().autoIncrement()();

  /// The list's name, e.g. "Kroger" or "Costco".
  ///
  /// UREQS: LSTORG-1
  TextColumn get name => text()();

  /// Whether this list is still active or has been archived.
  ///
  /// UREQS: LSTORG-3, LSTORG-4
  TextColumn get status => textEnum<ShoppingListStatus>()();

  /// When the list was created.
  ///
  /// UREQS: LSTORG-4
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the list was archived, if it has been.
  ///
  /// UREQS: LSTORG-3, LSTORG-4
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// A single item on a shopping list.
///
/// UREQS: LIST-2, LSTORG-2, SYNC-1
class ShoppingListItems extends Table {
  /// Row identifier.
  ///
  /// UREQS: LIST-2
  IntColumn get id => integer().autoIncrement()();

  /// The list this item belongs to.
  ///
  /// UREQS: LSTORG-1, LSTORG-2
  IntColumn get listId => integer().references(ShoppingLists, #id)();

  /// The list item's text as entered/generated (e.g., "Milk").
  ///
  /// UREQS: LIST-2, LIST-6
  TextColumn get name => text()();

  /// Coarse category, used the same way as [CatalogEntries.category].
  ///
  /// UREQS: LIST-6
  TextColumn get category => text()();

  /// How many of this item are planned, e.g. "Milk x2". Defaults to 1.
  ///
  /// UREQS: LSTORG-2
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  /// Whether this item has been matched to a basket entry yet.
  ///
  /// UREQS: LIST-2, LIST-4
  TextColumn get status => textEnum<ListItemStatus>()();
}

/// An item that has been added to a shopping basket, either by scanning a
/// product that matched a list item, or by manual entry.
///
/// UREQS: LIST-4, LIST-5, LSTORG-2
class BasketEntries extends Table {
  /// Row identifier.
  ///
  /// UREQS: LIST-4
  IntColumn get id => integer().autoIncrement()();

  /// The list this basket entry was added under.
  ///
  /// UREQS: LSTORG-1
  IntColumn get listId => integer().references(ShoppingLists, #id)();

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

  /// How many were actually added to the basket. Defaults to 1, and can
  /// differ from the linked list item's planned quantity (e.g. only 1 of
  /// 2 planned was in stock).
  ///
  /// UREQS: LSTORG-2
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  /// Price per unit (e.g., dollars per pound), if captured. `null` when
  /// only a flat [totalPrice] is known.
  ///
  /// UREQS: PRICE-1, PRICE-2, PRICE-10
  RealColumn get unitPrice => real().nullable()();

  /// The unit [unitPrice] is expressed in, e.g. "lb" or "oz". `null`
  /// whenever [unitPrice] is `null`.
  ///
  /// UREQS: PRICE-10
  TextColumn get unitLabel => text().nullable()();

  /// The flat total price for this entry, if captured. `null` when only a
  /// [unitPrice] is known (e.g. the total wasn't legible/entered).
  ///
  /// UREQS: PRICE-1, PRICE-2
  RealColumn get totalPrice => real().nullable()();

  /// When this entry was added.
  ///
  /// UREQS: LIST-4
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}
