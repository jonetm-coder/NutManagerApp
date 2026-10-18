import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import 'matching_service.dart';
import 'product_lookup_service.dart';

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
  /// [_database]. [productLookup] is injectable for testing; production
  /// code omits it and gets a real [ProductLookupService].
  ///
  /// UREQS: LSTORG-1, SYNC-1
  BasketService(this._database, this.listId, {ProductLookupService? productLookup})
    : _productLookup = productLookup ?? ProductLookupService() {
    unawaited(_reload());
  }

  final AppDatabase _database;
  final ProductLookupService _productLookup;
  final _matcher = MatchingService();

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
  /// Also kicks off [lookUpAndCacheBarcodes] for this one item in the
  /// background (not awaited, so adding the item itself isn't blocked on a
  /// network round-trip): looking up a real barcode now, while there's
  /// likely connectivity at home, means in-store scanning of the actual
  /// product later can resolve it from the local catalog alone, with no
  /// network call — PLOOKUP-1's "Check Products" action still exists as a
  /// manual catch-up for items added before this existed (e.g. seed data)
  /// or added while offline.
  ///
  /// UREQS: LSTORG-2, PLOOKUP-3
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
    unawaited(lookUpAndCacheBarcodes([(name: name, category: category)]));
  }

  /// How many by-name search results to cache per item. Deliberately
  /// generous and brand-agnostic: a vague item name (e.g. "English
  /// Muffins") covers many real-world SKUs/brands/sizes, and there's no
  /// way to know ahead of time which one the user actually owns — so
  /// every candidate returned gets cached (see [lookUpAndCacheBarcodes]),
  /// not just the first/top-ranked one, to maximize the chance that
  /// whichever exact product the user later scans is already known
  /// locally.
  static const int _searchCacheLimit = 25;

  /// For each of [items], first caches any of this household's *own past
  /// purchases* that plausibly match (see [_cacheHistoricalMatches]) —
  /// free, instant, and exact when it hits, since it's a product they
  /// already bought before, not a guess — then searches external open
  /// product databases by name and caches any candidates found
  /// (PLOOKUP-1), in case this trip buys a different brand/variant than
  /// last time. Network/parse failures are swallowed per-item by
  /// [ProductLookupService] itself; this never throws and never blocks on
  /// a missing connection. Returns how many candidates were cached across
  /// all items (history + external combined), for a caller that wants to
  /// report a count (e.g. the manual "Check Products" action).
  ///
  /// UREQS: PLOOKUP-1, PLOOKUP-3
  Future<int> lookUpAndCacheBarcodes(
    Iterable<({String name, String category})> items,
  ) async {
    var foundCount = 0;
    for (final item in items) {
      foundCount += await _cacheHistoricalMatches(item.name, item.category);

      final candidates = await _productLookup.searchByName(
        item.name,
        limit: _searchCacheLimit,
      );
      for (final candidate in candidates) {
        await _database
            .into(_database.catalogEntries)
            .insertOnConflictUpdate(
              CatalogEntriesCompanion.insert(
                barcode: candidate.barcode,
                name: candidate.name,
                category: item.category,
              ),
            );
        foundCount++;
      }
    }
    return foundCount;
  }

  /// Looks across this household's *entire* purchase history — every
  /// basket entry with a recorded barcode, on any list, active or
  /// archived — for products that plausibly match [name]/[category] (via
  /// the same [MatchingService] text matching used for scan confirmation,
  /// so "Thomas's English Mufins" correctly finds a past entry recorded
  /// as "Original English Muffins"), and caches each match's exact
  /// barcode into the local catalog. A confirmed past purchase is a far
  /// more reliable signal than a fresh by-name guess, which is why this
  /// runs before the external search in [lookUpAndCacheBarcodes] — a
  /// person is likely to buy the same product again, and when they do,
  /// their phone should already know its exact barcode with zero network
  /// calls.
  ///
  /// UREQS: PLOOKUP-1, PLOOKUP-3
  Future<int> _cacheHistoricalMatches(String name, String category) async {
    final target = ShoppingListItem(
      id: 0,
      listId: 0,
      name: name,
      category: category,
      quantity: 1,
      status: ListItemStatus.pending,
    );
    final history = await _database.select(_database.basketEntries).get();

    var foundCount = 0;
    final seenBarcodes = <String>{};
    for (final entry in history) {
      final barcode = entry.barcode;
      if (barcode == null || !seenBarcodes.add(barcode)) {
        continue;
      }
      final result = _matcher.match(
        productName: entry.productName,
        pendingItems: [target],
      );
      if (result.outcome == MatchOutcome.none) {
        continue;
      }
      await _database
          .into(_database.catalogEntries)
          .insertOnConflictUpdate(
            CatalogEntriesCompanion.insert(
              barcode: barcode,
              name: entry.productName,
              category: category,
            ),
          );
      foundCount++;
    }
    return foundCount;
  }

  /// Caches a specific external lookup result for [barcode] into the
  /// local catalog — used when an in-store scan misses the local catalog
  /// but a bounded, best-effort live by-barcode lookup (SCAN-11) finds
  /// it. Unlike [lookUpAndCacheBarcodes]'s by-name search, which can only
  /// guess at the right SKU among many similarly-named products, this
  /// targets the exact barcode that was actually scanned, so it's always
  /// precise when it succeeds at all.
  ///
  /// UREQS: SCAN-11
  Future<void> cacheExternalBarcodeMatch(
    String barcode, {
    required String name,
    String category = 'other',
  }) {
    return _database
        .into(_database.catalogEntries)
        .insertOnConflictUpdate(
          CatalogEntriesCompanion.insert(
            barcode: barcode,
            name: name,
            category: category,
          ),
        );
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
