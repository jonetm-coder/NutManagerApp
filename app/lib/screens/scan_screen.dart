import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/barcode_lookup_service.dart';
import '../services/basket_service.dart';
import '../services/matching_service.dart';
import '../services/scanner_service.dart';
import 'manual_add_flow.dart';
import 'match_confirmation_dialog.dart';

/// The camera scan screen: captures a frame on demand, decodes a barcode
/// (SCAN-1), looks it up, matches it to the shopping list (LIST-2/LIST-3),
/// and either adds it to the basket automatically, asks for confirmation,
/// or falls through to manual entry (SCAN-8) if the barcode isn't in the
/// catalog at all.
///
/// UREQS: SCAN-1, SCAN-8, PLAT-3
class ScanScreen extends StatefulWidget {
  /// Creates the screen, wired to [basketService] and [barcodeLookup].
  ///
  /// UREQS: SCAN-1
  const ScanScreen({
    super.key,
    required this.basketService,
    required this.barcodeLookup,
  });

  /// The basket/list state a successful scan updates.
  ///
  /// UREQS: LIST-2, LIST-5
  final BasketService basketService;

  /// Resolves a decoded barcode to a catalog product.
  ///
  /// UREQS: SCAN-1
  final BarcodeLookupService barcodeLookup;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _scanner = ScannerService();
  final _matcher = MatchingService();
  bool _isBusy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _scanner.initialize();
      if (mounted) setState(() {});
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
      _statusMessage = null;
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
      await _handleDecoded(barcode);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _handleDecoded(String barcode) async {
    final product = await widget.barcodeLookup.lookup(barcode);
    if (!mounted) {
      return;
    }

    if (product == null) {
      // SCAN-8: not found in the catalog, fall through to manual entry —
      // which itself attempts to match the typed name against the list
      // (see manual_add_flow.dart) rather than always adding unlinked.
      await showManualAddFlow(
        context: context,
        basketService: widget.basketService,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final result = _matcher.match(
      productName: product.name,
      productCategory: product.category,
      pendingItems: widget.basketService.pendingItems,
    );

    ShoppingListItem? matchedItem;
    switch (result.outcome) {
      case MatchOutcome.confident:
        matchedItem = result.candidates.first.listItem;
      case MatchOutcome.ambiguous:
        matchedItem = await showDialog<ShoppingListItem>(
          context: context,
          builder: (context) => MatchConfirmationDialog(
            productName: product.name,
            candidates: result.candidates,
          ),
        );
      case MatchOutcome.none:
        matchedItem = null;
    }

    await widget.basketService.addFromMatch(
      product: product,
      matchedItem: matchedItem,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _scanner.controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a product')),
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
              child: Text(_statusMessage!),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _isBusy ? null : _scanOnce,
              child: Text(_isBusy ? 'Scanning…' : 'Scan'),
            ),
          ),
        ],
      ),
    );
  }
}
