import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../data/database.dart';

/// Holds one shopping list's items and basket, backed by [AppDatabase]
/// (SYNC-1), and notifies listeners when either changes.
///
/// Scoped to a single [listId] (LSTORG-1) — the app can have several
/// shopping lists; each open list screen gets its own `BasketService`
/// instance rather than one global instance covering everything.
///
/// Phase 1 keeps this simple — a single `ChangeNotifier`, no external
/// state-management package — since there's no cloud data stream yet to
/// justify one. Revisit this if/when Phase 2's cloud sync makes plain
/// `ChangeNotifier` awkward, not before.
///
/// UREQS: LIST-2, LIST-4, LIST-5, LSTORG-1, LSTORG-2, SYNC-1
class BasketService extends ChangeNotifier {
  /// Creates the service for [listId] and loads current state from
  /// [_database].
  ///
  /// UREQS: LSTORG-1, SYNC-1
  BasketService(this._database, this.listId) {
    unawaited(_reload());
  }

  final AppDatabase _database;

  /// The shopping list this service's items/basket belong to.
  ///
  /// UREQS: LSTORG-1
  final int listId;

  List<ShoppingListItem> _listItems = [];
  List<BasketEntry> _basketEntries = [];

  /// All of this list's items, pending or found.
  ///
  /// UREQS: LIST-2
  List<ShoppingListItem> get listItems => List.unmodifiable(_listItems);

  /// This list's items not yet matched to a basket entry — the candidate
  /// pool [MatchingService] matches against.
  ///
  /// UREQS: LIST-2, LIST-3
  List<ShoppingListItem> get pendingItems => _listItems
      .where((item) => item.status == ListItemStatus.pending)
      .toList();

  /// Everything currently in this list's basket.
  ///
  /// UREQS: LIST-4
  List<BasketEntry> get basketEntries => List.unmodifiable(_basketEntries);

  /// Adds a planned item to the list itself (not the basket) — e.g.
  /// entered at home before a trip, independent of scanning.
  ///
  /// UREQS: LSTORG-2
  Future<void> addPlannedItem(
    String name, {
    String category = 'other',
    int quantity = 1,
  }) async {
    await _database
        .into(_database.shoppingListItems)
        .insert(
          ShoppingListItemsCompanion.insert(
            listId: listId,
            name: name,
            category: category,
            quantity: Value(quantity),
            status: ListItemStatus.pending,
          ),
        );
    await _reload();
  }

  /// Adds [product] to the basket. If [matchedItem] is given, that list
  /// item is marked found (LIST-2); if `null`, the entry is added with no
  /// list linkage (a scanned item not on the list at all).
  ///
  /// UREQS: LIST-2
  Future<void> addFromMatch({
    required CatalogEntry product,
    ShoppingListItem? matchedItem,
    int quantity = 1,
  }) async {
    await _addEntry(
      productName: product.name,
      barcode: product.barcode,
      matchedItem: matchedItem,
      quantity: quantity,
    );
  }

  /// Adds a basket entry manually, with no scan involved — the fallback
  /// path for an item scanning can't resolve (e.g., no catalog entry at
  /// all, per the "Fresh Basil" seed example).
  ///
  /// [matchedItem], if given, links the entry to that list item exactly
  /// like [addFromMatch] does (LIST-2) — callers should run the typed
  /// [name] through [MatchingService] first and pass the result here
  /// rather than always adding an unlinked entry. Skipping that step was
  /// a real Phase 1 bug: a manually-typed name never matched the list at
  /// all, which looked like a case-sensitivity bug but was actually this
  /// method never attempting to match in the first place.
  ///
  /// UREQS: LIST-5
  Future<void> addManually(
    String name, {
    ShoppingListItem? matchedItem,
    int quantity = 1,
  }) {
    return _addEntry(
      productName: name,
      matchedItem: matchedItem,
      quantity: quantity,
    );
  }

  Future<void> _addEntry({
    required String productName,
    String? barcode,
    ShoppingListItem? matchedItem,
    int quantity = 1,
  }) async {
    await _database
        .into(_database.basketEntries)
        .insert(
          BasketEntriesCompanion.insert(
            listId: listId,
            productName: productName,
            barcode: barcode == null ? const Value.absent() : Value(barcode),
            listItemId: matchedItem == null
                ? const Value.absent()
                : Value(matchedItem.id),
            quantity: Value(quantity),
          ),
        );
    if (matchedItem != null) {
      await _markFound(matchedItem.id);
    }
    await _reload();
  }

  /// Removes [entry] from the basket. If it was matched to a list item,
  /// that item reverts to pending rather than staying marked found for an
  /// item no longer in the basket.
  ///
  /// UREQS: LIST-4
  Future<void> remove(BasketEntry entry) async {
    await (_database.delete(
      _database.basketEntries,
    )..where((row) => row.id.equals(entry.id))).go();
    final linkedItemId = entry.listItemId;
    if (linkedItemId != null) {
      await _markPending(linkedItemId);
    }
    await _reload();
  }

  /// Updates a basket entry's actual quantity (e.g. only found 1 of the 2
  /// planned). Independent of the linked list item's planned quantity, if
  /// any.
  ///
  /// UREQS: LSTORG-2
  Future<void> updateBasketQuantity(BasketEntry entry, int quantity) async {
    await (_database.update(
      _database.basketEntries,
    )..where((row) => row.id.equals(entry.id))).write(
      BasketEntriesCompanion(quantity: Value(quantity)),
    );
    await _reload();
  }

  /// Updates a list item's planned quantity.
  ///
  /// UREQS: LSTORG-2
  Future<void> updateListItemQuantity(
    ShoppingListItem item,
    int quantity,
  ) async {
    await (_database.update(
      _database.shoppingListItems,
    )..where((row) => row.id.equals(item.id))).write(
      ShoppingListItemsCompanion(quantity: Value(quantity)),
    );
    await _reload();
  }

  /// Records a captured price on [entry] — either or both of [unitPrice]
  /// (with [unitLabel], e.g. "lb") and [totalPrice] may be given. Always
  /// called with values the user has confirmed (PriceOcrService's OCR
  /// output is a starting point shown for editing, never saved directly).
  ///
  /// UREQS: PRICE-1, PRICE-2, PRICE-10
  Future<void> setPrice(
    BasketEntry entry, {
    double? unitPrice,
    String? unitLabel,
    double? totalPrice,
  }) async {
    await (_database.update(
      _database.basketEntries,
    )..where((row) => row.id.equals(entry.id))).write(
      BasketEntriesCompanion(
        unitPrice: Value(unitPrice),
        unitLabel: Value(unitLabel),
        totalPrice: Value(totalPrice),
      ),
    );
    await _reload();
  }

  Future<void> _markFound(int listItemId) {
    return (_database.update(
      _database.shoppingListItems,
    )..where((row) => row.id.equals(listItemId))).write(
      const ShoppingListItemsCompanion(status: Value(ListItemStatus.found)),
    );
  }

  Future<void> _markPending(int listItemId) {
    return (_database.update(
      _database.shoppingListItems,
    )..where((row) => row.id.equals(listItemId))).write(
      const ShoppingListItemsCompanion(status: Value(ListItemStatus.pending)),
    );
  }

  Future<void> _reload() async {
    _listItems =
        await (_database.select(
          _database.shoppingListItems,
        )..where((row) => row.listId.equals(listId))).get();
    _basketEntries =
        await (_database.select(
          _database.basketEntries,
        )..where((row) => row.listId.equals(listId))).get();
    notifyListeners();
  }
}
