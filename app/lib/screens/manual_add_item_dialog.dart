import 'package:flutter/material.dart';

/// Lets the user manually add an item to the basket when scanning can't
/// resolve it — e.g., "Fresh Basil" in the Phase 1 seed data, which has no
/// catalog entry at all and so can only ever be resolved this way.
///
/// UREQS: LIST-5
class ManualAddItemDialog extends StatefulWidget {
  /// Creates the dialog.
  ///
  /// UREQS: LIST-5
  const ManualAddItemDialog({super.key});

  @override
  State<ManualAddItemDialog> createState() => _ManualAddItemDialogState();
}

class _ManualAddItemDialogState extends State<ManualAddItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add item'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Item name'),
        onSubmitted: (_) => _submit(context),
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
    Navigator.of(context).pop(name);
  }
}
