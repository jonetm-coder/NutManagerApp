import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/barcode_lookup_service.dart';
import '../services/basket_service.dart';
import '../services/matching_service.dart';
import '../services/product_lookup_service.dart';
import '../services/product_resolution_service.dart';
import '../services/scanner_service.dart';
import 'manual_add_item_dialog.dart';
import 'match_confirmation_dialog.dart';

/// Scans a product barcode outside the context of any specific shopping
/// list — e.g. "I'm out of this, add it to my list" while at home — then
/// identifies it via [ProductResolutionService]'s waterfall (local catalog
/// → purchase history → external lookup) before asking which list to add
/// it to (PLOOKUP-2).
///
/// UREQS: PLOOKUP-2, SCAN-1, SCAN-8
class ScanToAddScreen extends StatefulWidget {
  /// Creates the screen, backed by [database].
  ///
  /// UREQS: PLOOKUP-2
  const ScanToAddScreen({super.key, required this.database});

  /// UREQS: PLOOKUP-2
  final AppDatabase database;

  @override
  State<ScanToAddScreen> createState() => _ScanToAddScreenState();
}

class _ScanToAddScreenState extends State<ScanToAddScreen> {
  final _scanner = ScannerService();
  late final ProductResolutionService _resolver;
  bool _isBusy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _resolver = ProductResolutionService(
      widget.database,
      BarcodeLookupService(widget.database),
      ProductLookupService(),
    );
    unawaited(_initCamera());
  }

  Future<void> _initCamera() async {
    try {
      await _scanner.initialize();
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (error) {
      if (mounted) {
        setState(
          () => _statusMessage =
              'Camera unavailable: ${error.description ?? error.code}',
        );
      }
    }
  }

  @override
  void dispose() {
    unawaited(_scanner.dispose());
    super.dispose();
  }

  Future<void> _scanOnce() async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
      _statusMessage = 'Looking this up (local, then your history, then '
          'open databases)…';
    });
    try {
      final barcode = await _scanner.captureAndDecode();
      if (!mounted) {
        return;
      }
      if (barcode == null) {
        setState(() => _statusMessage = "Couldn't read a barcode — try again.");
        return;
      }
      final resolved = await _resolver.resolve(barcode);
      if (!mounted) {
        return;
      }

      String name;
      String category;
      String? resolvedBarcode;
      if (resolved != null) {
        name = resolved.name;
        category = resolved.category;
        resolvedBarcode = resolved.barcode;
      } else {
        // All three tiers missed (SCAN-8's pattern): ask for a name. The
        // destination dialog below asks for quantity, so this dialog's own
        // quantity field is deliberately discarded here rather than
        // prompting for it twice.
        final entered = await showDialog<(String, int)>(
          context: context,
          builder: (context) =>
              const ManualAddItemDialog(title: "What is this?"),
        );
        if (entered == null) {
          setState(() => _statusMessage = null);
          return;
        }
        name = entered.$1;
        category = 'other';
        resolvedBarcode = barcode;
      }

      if (!mounted) {
        return;
      }
      final destination = await showDialog<(ShoppingList, int)>(
        context: context,
        builder: (context) =>
            _DestinationDialog(database: widget.database, productName: name),
      );
      if (destination == null) {
        setState(() => _statusMessage = null);
        return;
      }
      final (targetList, quantity) = destination;

      final basketService = BasketService(widget.database, targetList.id);
      final matchResult = MatchingService().match(
        productName: name,
        productCategory: category,
        pendingItems: basketService.pendingItems,
      );
      ShoppingListItem? matchedItem;
      switch (matchResult.outcome) {
        case MatchOutcome.confident:
          matchedItem = matchResult.candidates.first.listItem;
        case MatchOutcome.ambiguous:
          if (!mounted) {
            basketService.dispose();
            return;
          }
          matchedItem = await showDialog<ShoppingListItem>(
            context: context,
            builder: (context) => MatchConfirmationDialog(
              productName: name,
              candidates: matchResult.candidates,
              allPendingItems: basketService.pendingItems,
            ),
          );
        case MatchOutcome.none:
          matchedItem = null;
      }

      await basketService.addFromMatch(
        product: CatalogEntry(
          barcode: resolvedBarcode,
          name: name,
          category: category,
        ),
        matchedItem: matchedItem,
        quantity: quantity,
      );
      // Same history-first/broader-search treatment as a planned item or
      // an in-store scan (PLOOKUP-3): broaden the local catalog around
      // this now-confirmed product name/category in the background.
      // Safe to outlive the dispose() below — this never calls
      // notifyListeners(), only writes to the database.
      unawaited(
        basketService.lookUpAndCacheBarcodes([(name: name, category: category)]),
      );
      basketService.dispose();

      if (mounted) {
        setState(
          () => _statusMessage = 'Added "$name" to "${targetList.name}".',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _scanner.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan to Add')),
      body: Column(
        children: [
          Expanded(
            child: controller != null && controller.value.isInitialized
                ? CameraPreview(controller)
                : Center(child: Text(_statusMessage ?? 'Starting camera…')),
          ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_statusMessage!, textAlign: TextAlign.center),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _isBusy ? null : _scanOnce,
              child: Text(_isBusy ? 'Working…' : 'Scan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationDialog extends StatefulWidget {
  const _DestinationDialog({required this.database, required this.productName});

  final AppDatabase database;
  final String productName;

  @override
  State<_DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<_DestinationDialog> {
  late final Future<List<ShoppingList>> _lists;
  final _newListController = TextEditingController();
  /// Either a [ShoppingList] (an existing list was picked) or
  /// [_newListMarker] ("create a new list" was picked); `null` if nothing
  /// is selected yet. Unified into one field, rather than a separate
  /// `ShoppingList?` plus a `bool`, so the whole group can sit under a
  /// single `RadioGroup<Object>`.
  Object? _selection;
  int _quantity = 1;

  static const Object _newListMarker = Object();

  bool get _creatingNew => identical(_selection, _newListMarker);
  ShoppingList? get _selected =>
      _selection is ShoppingList ? _selection as ShoppingList : null;

  @override
  void initState() {
    super.initState();
    _lists = (widget.database.select(
      widget.database.shoppingLists,
    )..where((row) => row.status.equalsValue(ShoppingListStatus.active))).get();
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add "${widget.productName}" to…'),
      content: FutureBuilder<List<ShoppingList>>(
        future: _lists,
        builder: (context, snapshot) {
          final lists = snapshot.data;
          if (lists == null) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return SizedBox(
            width: double.maxFinite,
            child: RadioGroup<Object>(
              groupValue: _selection,
              onChanged: (value) => setState(() => _selection = value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final list in lists)
                    RadioListTile<Object>(value: list, title: Text(list.name)),
                  RadioListTile<Object>(
                    value: _newListMarker,
                    title: TextField(
                      controller: _newListController,
                      decoration: const InputDecoration(
                        hintText: 'New list name',
                      ),
                      onTap: () => setState(() => _selection = _newListMarker),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Quantity'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Text('$_quantity'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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

  Future<void> _submit(BuildContext context) async {
    var target = _selected;
    if (_creatingNew) {
      final name = _newListController.text.trim();
      if (name.isEmpty) {
        return;
      }
      final id = await widget.database
          .into(widget.database.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              name: name,
              status: ShoppingListStatus.active,
            ),
          );
      target = ShoppingList(
        id: id,
        name: name,
        status: ShoppingListStatus.active,
        createdAt: DateTime.now(),
        archivedAt: null,
      );
      if (!context.mounted) {
        return;
      }
    }
    if (target == null) {
      return;
    }
    Navigator.of(context).pop((target, _quantity));
  }
}
