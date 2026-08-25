import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../data/database.dart';

/// Holds the current shopping list and basket state, backed by [AppDatabase]
/// (SYNC-1), and notifies listeners when either changes.
///
/// Phase 1 keeps this simple — a single `ChangeNotifier`, no external
/// state-management package — since there's no cloud data stream yet to
/// justify one. Revisit this if/when Phase 2's cloud sync makes plain
/// `ChangeNotifier` awkward, not before.
///
/// UREQS: LIST-2, LIST-4, LIST-5, SYNC-1
class BasketService extends ChangeNotifier {
  /// Creates the service and loads current state from [_database].
  ///
  /// UREQS: SYNC-1
  BasketService(this._database) {
    unawaited(_reload());
  }

  final AppDatabase _database;

  List<ShoppingListItem> _listItems = [];
  List<BasketEntry> _basketEntries = [];

  /// All shopping list items, pending or found.
  ///
  /// UREQS: LIST-2
  List<ShoppingListItem> get listItems => List.unmodifiable(_listItems);

  /// Shopping list items not yet matched to a basket entry — the candidate
  /// pool [MatchingService] matches against.
  ///
  /// UREQS: LIST-2, LIST-3
  List<ShoppingListItem> get pendingItems => _listItems
      .where((item) => item.status == ListItemStatus.pending)
      .toList();

  /// Everything currently in the basket.
  ///
  /// UREQS: LIST-4
  List<BasketEntry> get basketEntries => List.unmodifiable(_basketEntries);

  /// Adds [product] to the basket. If [matchedItem] is given, that list
  /// item is marked found (LIST-2); if `null`, the entry is added with no
  /// list linkage (a scanned item not on the list at all).
  ///
  /// UREQS: LIST-2
  Future<void> addFromMatch({
    required CatalogEntry product,
    ShoppingListItem? matchedItem,
  }) async {
    await _database
        .into(_database.basketEntries)
        .insert(
          BasketEntriesCompanion.insert(
            productName: product.name,
            barcode: Value(product.barcode),
            listItemId: matchedItem == null
                ? const Value.absent()
                : Value(matchedItem.id),
          ),
        );
    if (matchedItem != null) {
      await _markFound(matchedItem.id);
    }
    await _reload();
  }

  /// Adds a basket entry manually, with no scan involved — the fallback
  /// path for an item scanning can't resolve (e.g., no catalog entry at
  /// all, per the "Fresh Basil" seed example).
  ///
  /// UREQS: LIST-5
  Future<void> addManually(String name) async {
    await _database
        .into(_database.basketEntries)
        .insert(BasketEntriesCompanion.insert(productName: name));
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
    _listItems = await _database.select(_database.shoppingListItems).get();
    _basketEntries = await _database.select(_database.basketEntries).get();
    notifyListeners();
  }
}
