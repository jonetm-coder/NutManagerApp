import 'package:flutter/material.dart';

import '../data/database.dart';
import 'archived_lists_screen.dart';
import 'scan_to_add_screen.dart';
import 'shopping_list_screen.dart';

/// Shows the household's active shopping lists (LSTORG-1), lets the user
/// create a new named one (typically per-store), jump to
/// [ArchivedListsScreen], or scan a product to add from home
/// ([ScanToAddScreen], PLOOKUP-2) without first opening a specific list.
///
/// UREQS: LSTORG-1, LSTORG-4, LSTORG-5, PLOOKUP-2
class ShoppingListsHomeScreen extends StatefulWidget {
  /// Creates the screen, backed by [database].
  ///
  /// UREQS: LSTORG-1
  const ShoppingListsHomeScreen({super.key, required this.database});

  /// UREQS: LSTORG-1
  final AppDatabase database;

  @override
  State<ShoppingListsHomeScreen> createState() =>
      _ShoppingListsHomeScreenState();
}

class _ShoppingListsHomeScreenState extends State<ShoppingListsHomeScreen> {
  late Future<List<ShoppingList>> _activeLists;

  @override
  void initState() {
    super.initState();
    _activeLists = _loadActiveLists();
  }

  Future<List<ShoppingList>> _loadActiveLists() {
    return (widget.database.select(
      widget.database.shoppingLists,
    )..where((row) => row.status.equalsValue(ShoppingListStatus.active))).get();
  }

  void _refresh() {
    setState(() {
      _activeLists = _loadActiveLists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archived lists',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      ArchivedListsScreen(database: widget.database),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ShoppingList>>(
        future: _activeLists,
        builder: (context, snapshot) {
          final lists = snapshot.data;
          if (lists == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lists.isEmpty) {
            return const Center(child: Text('No shopping lists yet.'));
          }
          return ListView(
            children: [
              for (final list in lists)
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: Text(list.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ShoppingListScreen(
                          database: widget.database,
                          list: list,
                        ),
                      ),
                    );
                    _refresh();
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scanToAdd',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      ScanToAddScreen(database: widget.database),
                ),
              );
              _refresh();
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan to Add'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'newList',
            onPressed: () => _createList(context),
            tooltip: 'New list',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _createList(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewListDialog(),
    );
    if (name == null || name.isEmpty) {
      return;
    }
    await widget.database
        .into(widget.database.shoppingLists)
        .insert(
          ShoppingListsCompanion.insert(
            name: name,
            status: ShoppingListStatus.active,
          ),
        );
    _refresh();
  }
}

class _NewListDialog extends StatefulWidget {
  const _NewListDialog();

  @override
  State<_NewListDialog> createState() => _NewListDialogState();
}

class _NewListDialogState extends State<_NewListDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New shopping list'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Kroger'),
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('Create'),
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
