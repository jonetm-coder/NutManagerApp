import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(NutManagerApp(database: AppDatabase()));
}

/// Root widget of the app.
///
/// UREQS: PLAT-1, PLAT-3
class NutManagerApp extends StatelessWidget {
  /// Creates the root widget, backed by [database].
  ///
  /// UREQS: PLAT-1, SYNC-1
  const NutManagerApp({super.key, required this.database});

  /// The app's local database, passed down to whichever screen needs it —
  /// no single global `BasketService` any more now that the app has
  /// multiple lists (LSTORG-1); each list screen owns its own, scoped to
  /// that list's id.
  ///
  /// UREQS: SYNC-1, LSTORG-1
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutManagerApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: HomeScreen(database: database),
    );
  }
}
