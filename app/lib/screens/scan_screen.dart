import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/barcode_lookup_service.dart';
import '../services/basket_service.dart';
import '../services/matching_service.dart';
import '../services/product_lookup_service.dart';
import '../services/scanner_service.dart';
import 'manual_add_flow.dart';
import 'match_confirmation_dialog.dart';

/// The camera scan screen: automatically retries capturing a frame and
/// decoding a barcode (SCAN-1) as soon as the camera is ready, with no
/// button press required — it stops retrying the instant a barcode is
/// read, then looks it up, matches it to the shopping list
/// (LIST-2/LIST-3), and either adds it to the basket automatically, asks
/// for confirmation, or falls through to manual entry (SCAN-8) if the
/// barcode isn't in the catalog at all. A visible "Enter manually"
/// button is always available as an escape hatch for a barcode that
/// genuinely won't decode (e.g. damaged packaging), so auto-retrying
/// forever is never a dead end.
///
/// On a local-catalog miss, also tries a short, bounded live by-barcode
/// lookup as a backup (SCAN-11) before giving up to manual entry — a
/// by-name search (PLOOKUP-1/PLOOKUP-3) can only guess at which SKU among
/// many similarly-named products the user actually has, and a real report
/// showed that guess can miss; looking up the *exact* scanned barcode is
/// precise. This is a deliberate, bounded exception to this screen
/// otherwise never touching the network (SCAN-4/SYNC-3): a catalog hit is
/// still instant and fully offline as always, and a miss with no
/// connectivity still falls through to manual entry within a few seconds,
/// not blocked indefinitely.
///
/// UREQS: SCAN-1, SCAN-8, SCAN-11, PLAT-3
class ScanScreen extends StatefulWidget {
  /// Creates the screen, wired to [basketService] and [barcodeLookup].
  /// [productLookup] is injectable for testing; production code omits it
  /// and gets a real [ProductLookupService].
  ///
  /// UREQS: SCAN-1, SCAN-11
  ScanScreen({
    super.key,
    required this.basketService,
    required this.barcodeLookup,
    ProductLookupService? productLookup,
  }) : productLookup = productLookup ?? ProductLookupService();

  /// The basket/list state a successful scan updates.
  ///
  /// UREQS: LIST-2, LIST-5
  final BasketService basketService;

  /// Resolves a decoded barcode to a catalog product.
  ///
  /// UREQS: SCAN-1
  final BarcodeLookupService barcodeLookup;

  /// Backs the bounded live-lookup fallback (SCAN-11).
  ///
  /// UREQS: SCAN-11
  final ProductLookupService productLookup;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _scanner = ScannerService();
  final _matcher = MatchingService();
  String? _statusMessage;

  /// Guards the auto-scan loop below: true while it should keep retrying.
  /// Set false the instant a barcode is read (stopping further attempts)
  /// or when the screen is disposed.
  bool _autoScanActive = true;

  /// True from the moment a decoded barcode starts being handled until
  /// this screen pops — disables the "Enter manually" button for that
  /// window, so a tap can't race a second, conflicting manual-entry flow
  /// against the one [_handleDecoded] may itself fall through to.
  bool _processingDecode = false;

  /// Delay between a failed capture attempt and the next one — long
  /// enough not to hammer the camera/CPU pointlessly, short enough that
  /// "point the camera and it just works" doesn't feel laggy.
  static const _autoScanRetryDelay = Duration(milliseconds: 350);

  /// Caps the extra wait on a local-catalog miss before falling through to
  /// manual entry — bounds the worst case for an offline in-store scan
  /// (no connectivity would otherwise mean waiting out
  /// [ProductLookupService.lookupByBarcode]'s own, longer internal
  /// timeouts across two sequential sources).
  static const _liveLookupTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _scanner.initialize();
      if (!mounted) {
        return;
      }
      setState(() {});
      unawaited(_runAutoScanLoop());
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
    _autoScanActive = false;
    unawaited(_scanner.dispose());
    super.dispose();
  }

  /// Repeatedly captures and attempts to decode a frame, with no button
  /// press needed, until one succeeds — then stops immediately and hands
  /// off to [_handleDecoded]. A failed attempt (nothing readable in that
  /// frame) just retries after [_autoScanRetryDelay], silently; this
  /// isn't a terminal error the way a single manual "Scan" tap failing
  /// used to be, since there's always another frame coming.
  Future<void> _runAutoScanLoop() async {
    while (mounted && _autoScanActive) {
      final barcode = await _scanner.captureAndDecode();
      if (!mounted || !_autoScanActive) {
        return;
      }
      if (barcode != null) {
        _autoScanActive = false;
        await _handleDecoded(barcode);
        return;
      }
      await Future<void>.delayed(_autoScanRetryDelay);
    }
  }

  /// The "Enter manually" escape hatch: stops auto-scanning and goes
  /// straight to the same manual-entry flow SCAN-8 falls through to on a
  /// catalog miss, for a barcode that genuinely won't decode at all
  /// (rather than one that decodes but isn't recognized).
  Future<void> _goToManualEntry() async {
    if (_processingDecode) {
      return;
    }
    _autoScanActive = false;
    setState(() => _processingDecode = true);
    await showManualAddFlow(context: context, basketService: widget.basketService);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDecoded(String barcode) async {
    setState(() => _processingDecode = true);
    var product = await widget.barcodeLookup.lookup(barcode);
    if (!mounted) {
      return;
    }

    if (product == null) {
      product = await _tryLiveLookup(barcode);
      if (!mounted) {
        return;
      }
    }

    if (product == null) {
      // SCAN-8: not found locally or live, fall through to manual entry —
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
    final resolvedProduct = product;

    final result = _matcher.match(
      productName: resolvedProduct.name,
      productCategory: resolvedProduct.category,
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
            productName: resolvedProduct.name,
            candidates: result.candidates,
            allPendingItems: widget.basketService.pendingItems,
          ),
        );
      case MatchOutcome.none:
        matchedItem = null;
    }

    await widget.basketService.addFromMatch(
      product: resolvedProduct,
      matchedItem: matchedItem,
    );
    // The same history-first/broader-search treatment addPlannedItem gets
    // (PLOOKUP-3) applies to a product identified by scanning too: now
    // that this exact product's name/category is confirmed, broaden the
    // local catalog around it in the background (never blocks this scan).
    unawaited(
      widget.basketService.lookUpAndCacheBarcodes([
        (name: resolvedProduct.name, category: resolvedProduct.category),
      ]),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// SCAN-11: on a local-catalog miss, tries a short, bounded live
  /// by-barcode lookup as a backup before manual entry. Caches a hit into
  /// the local catalog (so a repeat scan of the same product later in the
  /// trip resolves offline, as usual) and re-resolves it through
  /// [BarcodeLookupService.lookup] to get a real [CatalogEntry]. Returns
  /// `null` on a miss, a timeout, or no connectivity — this never throws
  /// and never waits past [_liveLookupTimeout].
  Future<CatalogEntry?> _tryLiveLookup(String barcode) async {
    setState(() => _statusMessage = 'Checking online for this product…');
    final external = await widget.productLookup
        .lookupByBarcode(barcode)
        .timeout(_liveLookupTimeout, onTimeout: () => null);
    if (!mounted) {
      return null;
    }
    if (external == null) {
      setState(() => _statusMessage = null);
      return null;
    }
    await widget.basketService.cacheExternalBarcodeMatch(
      barcode,
      name: external.name,
    );
    if (!mounted) {
      return null;
    }
    setState(() => _statusMessage = null);
    return widget.barcodeLookup.lookup(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _scanner.controller;
    final cameraReady = controller != null && controller.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a product')),
      body: Column(
        children: [
          Expanded(
            child: cameraReady
                ? CameraPreview(controller)
                : Center(child: Text(_statusMessage ?? 'Starting camera…')),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cameraReady) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: Text(
                    _statusMessage ??
                        (cameraReady
                            ? 'Point the camera at a barcode…'
                            : 'Starting camera…'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextButton(
              onPressed: _processingDecode ? null : _goToManualEntry,
              child: const Text("Can't scan it? Enter manually"),
            ),
          ),
        ],
      ),
    );
  }
}
