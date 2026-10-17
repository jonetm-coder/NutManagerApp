import 'package:flutter/material.dart';

import '../data/database.dart';
import 'shopping_lists_home_screen.dart';

/// The app's top-level landing screen — a place to navigate to Shopping
/// Lists (the only section built so far) and, as the app grows, whatever
/// future sections join it (e.g. nutrition planning, per the longer-term
/// ecosystem described in CLAUDE.md). Deliberately has no placeholder
/// entries for those yet-unbuilt sections.
///
/// UREQS: LSTORG-5
class HomeScreen extends StatelessWidget {
  /// Creates the screen, backed by [database].
  ///
  /// UREQS: LSTORG-5
  const HomeScreen({super.key, required this.database});

  /// Passed through to whichever section screen is opened.
  ///
  /// UREQS: LSTORG-5
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NutManager')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Shopping Lists'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    ShoppingListsHomeScreen(database: database),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
