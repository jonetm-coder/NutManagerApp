import 'package:flutter/material.dart';

import 'data/database.dart';
import 'screens/shopping_list_screen.dart';
import 'services/basket_service.dart';

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
  NutManagerApp({super.key, required AppDatabase database})
    : basketService = BasketService(database);

  /// The basket/list state shared across the app.
  ///
  /// UREQS: LIST-2, LIST-4, LIST-5
  final BasketService basketService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutManagerApp',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green)),
      home: ShoppingListScreen(basketService: basketService),
    );
  }
}
