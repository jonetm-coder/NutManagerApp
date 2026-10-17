import 'package:flutter/material.dart';

/// Lets the user manually enter an item name and quantity — used both to
/// add an item straight to the basket when scanning can't resolve it
/// (LIST-5), and to add a planned item to a list ahead of a trip
/// (LSTORG-2). Returns `(name, quantity)`, or `null` if cancelled.
///
/// UREQS: LIST-5, LSTORG-2
class ManualAddItemDialog extends StatefulWidget {
  /// Creates the dialog. [title] lets callers distinguish "Add to Basket"
  /// from "Add to List" in the UI even though the underlying dialog is
  /// shared.
  ///
  /// UREQS: LIST-5, LSTORG-2
  const ManualAddItemDialog({super.key, this.title = 'Add item'});

  /// The dialog's title.
  ///
  /// UREQS: LIST-5, LSTORG-2
  final String title;

  @override
  State<ManualAddItemDialog> createState() => _ManualAddItemDialogState();
}

class _ManualAddItemDialogState extends State<ManualAddItemDialog> {
  final _controller = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Item name'),
            onSubmitted: (_) => _submit(context),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Quantity'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Decrease quantity',
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Text('$_quantity', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Increase quantity',
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop((name, _quantity));
  }
}
