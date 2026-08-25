import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/barcode_lookup_service.dart';
import '../services/basket_service.dart';
import 'manual_add_item_dialog.dart';
import 'scan_screen.dart';

/// The main Phase 1 screen: the shopping list and the basket.
///
/// This screen makes no network calls, satisfying the
/// no-action-blocked-by-connectivity requirement by construction.
///
/// UREQS: LIST-2, LIST-4, LIST-5, SYNC-3
class ShoppingListScreen extends StatelessWidget {
  /// Creates the screen backed by [basketService] and [barcodeLookup].
  ///
  /// UREQS: LIST-2, LIST-4, LIST-5, SCAN-1
  const ShoppingListScreen({
    super.key,
    required this.basketService,
    required this.barcodeLookup,
  });

  /// The basket/list state this screen displays and mutates.
  ///
  /// UREQS: LIST-2, LIST-4, LIST-5
  final BasketService basketService;

  /// Passed through to [ScanScreen] when the user taps "Scan".
  ///
  /// UREQS: SCAN-1
  final BarcodeLookupService barcodeLookup;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: ListenableBuilder(
        listenable: basketService,
        builder: (context, _) => ListView(
          children: [
            const _SectionHeader('Shopping List'),
            for (final item in basketService.listItems)
              CheckboxListTile(
                value: item.status == ListItemStatus.found,
                onChanged: null,
                title: Text(item.name),
              ),
            const Divider(),
            const _SectionHeader('Basket'),
            if (basketService.basketEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Nothing in the basket yet.'),
              ),
            for (final entry in basketService.basketEntries)
              ListTile(
                title: Text(entry.productName),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remove from basket',
                  onPressed: () => basketService.remove(entry),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Row(
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
            heroTag: 'add',
            onPressed: () => _addManually(context),
            tooltip: 'Add item',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _addManually(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const ManualAddItemDialog(),
    );
    if (name != null) {
      await basketService.addManually(name);
    }
  }

  Future<void> _scan(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ScanScreen(
          basketService: basketService,
          barcodeLookup: barcodeLookup,
        ),
      ),
    );
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
