import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../data/database.dart';
import 'shopping_list_screen.dart';

/// Browses archived shopping lists (LSTORG-4), sorted most-recently
/// archived first, each row showing its name and archive date. Opens a
/// list read-only — an archived trip is history, not something to keep
/// editing day to day.
///
/// UREQS: LSTORG-4
class ArchivedListsScreen extends StatefulWidget {
  /// Creates the screen, backed by [database].
  ///
  /// UREQS: LSTORG-4
  const ArchivedListsScreen({super.key, required this.database});

  /// UREQS: LSTORG-4
  final AppDatabase database;

  @override
  State<ArchivedListsScreen> createState() => _ArchivedListsScreenState();
}

class _ArchivedListsScreenState extends State<ArchivedListsScreen> {
  late Future<List<ShoppingList>> _archivedLists;

  @override
  void initState() {
    super.initState();
    _archivedLists = _loadArchivedLists();
  }

  Future<List<ShoppingList>> _loadArchivedLists() {
    return (widget.database.select(widget.database.shoppingLists)
          ..where((row) => row.status.equalsValue(ShoppingListStatus.archived))
          ..orderBy([(row) => OrderingTerm.desc(row.archivedAt)]))
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Lists')),
      body: FutureBuilder<List<ShoppingList>>(
        future: _archivedLists,
        builder: (context, snapshot) {
          final lists = snapshot.data;
          if (lists == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lists.isEmpty) {
            return const Center(child: Text('No archived lists yet.'));
          }
          return ListView(
            children: [
              for (final list in lists)
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: Text(list.name),
                  subtitle: Text(_formatDate(list.archivedAt!)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ShoppingListScreen(
                        database: widget.database,
                        list: list,
                        readOnly: true,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'Archived $y-$m-$d';
  }
}
