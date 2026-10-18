import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/barcode_lookup_service.dart';
import '../services/basket_service.dart';
import 'manual_add_flow.dart';
import 'price_entry_screen.dart';
import 'scan_screen.dart';

/// One shopping list: its planned items and its basket (LSTORG-1).
///
/// This screen makes no network calls itself, satisfying the
/// no-action-blocked-by-connectivity requirement by construction — the
/// one explicitly-online exception is "Check Products" (PLOOKUP-1), which
/// is clearly a separate, user-initiated action, not something scanning
/// or viewing the list depends on.
///
/// UREQS: LIST-2, LIST-4, LIST-5, LSTORG-1, LSTORG-2, LSTORG-3, PLOOKUP-1, SYNC-3
class ShoppingListScreen extends StatefulWidget {
  /// Creates the screen for [list], backed by [database]. [readOnly] hides
  /// every mutating action — used when opened from [ArchivedListsScreen],
  /// since an archived trip is history, not something to keep editing.
  ///
  /// UREQS: LSTORG-1, LSTORG-4
  const ShoppingListScreen({
    super.key,
    required this.database,
    required this.list,
    this.readOnly = false,
  });

  /// UREQS: LSTORG-1
  final AppDatabase database;

  /// The list this screen displays.
  ///
  /// UREQS: LSTORG-1
  final ShoppingList list;

  /// Whether this is a read-only (archived) view.
  ///
  /// UREQS: LSTORG-4
  final bool readOnly;

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final BasketService _basketService;
  late final BarcodeLookupService _barcodeLookup;
  bool _isCheckingProducts = false;

  @override
  void initState() {
    super.initState();
    _basketService = BasketService(widget.database, widget.list.id);
    _barcodeLookup = BarcodeLookupService(widget.database);
  }

  @override
  void dispose() {
    _basketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        actions: widget.readOnly
            ? null
            : [
                IconButton(
                  icon: _isCheckingProducts
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.travel_explore),
                  tooltip: 'Check Products',
                  onPressed: _isCheckingProducts
                      ? null
                      : () => _checkProducts(context),
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  tooltip: 'Archive this list',
                  onPressed: () => _archive(context),
                ),
              ],
      ),
      body: ListenableBuilder(
        listenable: _basketService,
        builder: (context, _) => ListView(
          children: [
            const _SectionHeader('Shopping List'),
            for (final item in _basketService.listItems)
              CheckboxListTile(
                value: item.status == ListItemStatus.found,
                onChanged: null,
                title: Text(_withQuantity(item.name, item.quantity)),
              ),
            const Divider(),
            const _SectionHeader('Basket'),
            if (_basketService.basketEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Nothing in the basket yet.'),
              ),
            for (final entry in _basketService.basketEntries)
              ListTile(
                title: Text(_withQuantity(entry.productName, entry.quantity)),
                subtitle: _priceSubtitle(entry),
                trailing: widget.readOnly
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sell_outlined),
                            tooltip: 'Set price',
                            onPressed: () => _setPrice(context, entry),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove from basket',
                            onPressed: () => _basketService.remove(entry),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
      floatingActionButton: widget.readOnly
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'scan',
                  onPressed: () => _scan(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan'),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'addToList',
                  onPressed: () => showAddPlannedItemFlow(
                    context: context,
                    basketService: _basketService,
                  ),
                  tooltip: 'Add to list',
                  child: const Icon(Icons.playlist_add),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'addToBasket',
                  onPressed: () => showManualAddFlow(
                    context: context,
                    basketService: _basketService,
                  ),
                  tooltip: 'Add to basket',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }

  String _withQuantity(String name, int quantity) =>
      quantity > 1 ? '$name ×$quantity' : name;

  Widget? _priceSubtitle(BasketEntry entry) {
    final parts = <String>[];
    if (entry.totalPrice != null) {
      parts.add('\$${entry.totalPrice!.toStringAsFixed(2)}');
    }
    if (entry.unitPrice != null) {
      parts.add('\$${entry.unitPrice!.toStringAsFixed(2)}/${entry.unitLabel}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return Text(parts.join(' · '));
  }

  Future<void> _scan(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ScanScreen(
          basketService: _basketService,
          barcodeLookup: _barcodeLookup,
        ),
      ),
    );
  }

  Future<void> _setPrice(BuildContext context, BasketEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            PriceEntryScreen(basketService: _basketService, entry: entry),
      ),
    );
  }

  Future<void> _archive(BuildContext context) async {
    await (widget.database.update(
      widget.database.shoppingLists,
    )..where((row) => row.id.equals(widget.list.id))).write(
      ShoppingListsCompanion(
        status: const Value(ShoppingListStatus.archived),
        archivedAt: Value(DateTime.now()),
      ),
    );
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// "Check Products" (PLOOKUP-1): searches an external open product
  /// database for each pending item's name and adds any candidates found
  /// to the local catalog, so in-store scanning has a higher hit rate. A
  /// manual catch-up for items that predate [BasketService.addPlannedItem]
  /// doing this automatically (PLOOKUP-3) or were added without
  /// connectivity — the one explicitly-online action on this otherwise-
  /// offline screen.
  Future<void> _checkProducts(BuildContext context) async {
    setState(() => _isCheckingProducts = true);
    int foundCount;
    try {
      foundCount = await _basketService.lookUpAndCacheBarcodes([
        for (final item in _basketService.pendingItems)
          (name: item.name, category: item.category),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isCheckingProducts = false);
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            foundCount == 0
                ? 'No candidate products found.'
                : 'Found $foundCount candidate product(s) for your list.',
          ),
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
