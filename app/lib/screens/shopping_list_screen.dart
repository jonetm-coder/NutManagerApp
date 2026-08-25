import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/basket_service.dart';
import 'manual_add_item_dialog.dart';

/// The main Phase 1 screen: the shopping list and the basket.
///
/// Scanning (camera + ML Kit) is wired in during Stage 2; for now, items
/// reach the basket only via manual add. The underlying
/// [BasketService.addFromMatch] path is already implemented and tested —
/// this screen just doesn't have a scan button to trigger it yet.
///
/// This screen makes no network calls, satisfying the
/// no-action-blocked-by-connectivity requirement by construction.
///
/// UREQS: LIST-2, LIST-4, LIST-5, SYNC-3
class ShoppingListScreen extends StatelessWidget {
  /// Creates the screen backed by [basketService].
  ///
  /// UREQS: LIST-2, LIST-4, LIST-5
  const ShoppingListScreen({super.key, required this.basketService});

  /// The basket/list state this screen displays and mutates.
  ///
  /// UREQS: LIST-2, LIST-4, LIST-5
  final BasketService basketService;

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addManually(context),
        tooltip: 'Add item',
        child: const Icon(Icons.add),
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
