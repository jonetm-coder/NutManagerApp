import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/basket_service.dart';
import '../services/price_ocr_service.dart';
import '../services/scanner_service.dart';

/// Captures a price for [entry] — scan a shelf tag/price label (OCR via
/// [PriceOcrService]) and/or enter it manually, recognizing a flat total
/// and/or a per-unit price (e.g. $/lb) (PRICE-1, PRICE-2, PRICE-10).
///
/// OCR results only ever pre-fill the editable fields below — nothing is
/// saved until the user taps Save, since price-tag OCR is a heuristic
/// (see [PriceOcrService]), not something to trust blindly for a value
/// that affects money.
///
/// UREQS: PRICE-1, PRICE-2, PRICE-10
class PriceEntryScreen extends StatefulWidget {
  /// Creates the screen for [entry], saving through [basketService].
  ///
  /// UREQS: PRICE-1
  const PriceEntryScreen({
    super.key,
    required this.basketService,
    required this.entry,
  });

  /// UREQS: PRICE-1
  final BasketService basketService;

  /// The basket entry being priced.
  ///
  /// UREQS: PRICE-1
  final BasketEntry entry;

  @override
  State<PriceEntryScreen> createState() => _PriceEntryScreenState();
}

class _PriceEntryScreenState extends State<PriceEntryScreen> {
  final _scanner = ScannerService();
  final _priceOcr = PriceOcrService();
  late final TextEditingController _totalController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _unitLabelController;
  bool _isBusy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController(
      text: widget.entry.totalPrice?.toStringAsFixed(2) ?? '',
    );
    _unitPriceController = TextEditingController(
      text: widget.entry.unitPrice?.toStringAsFixed(2) ?? '',
    );
    _unitLabelController = TextEditingController(
      text: widget.entry.unitLabel ?? '',
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
    unawaited(_priceOcr.dispose());
    _totalController.dispose();
    _unitPriceController.dispose();
    _unitLabelController.dispose();
    super.dispose();
  }

  Future<void> _scanPriceTag() async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    try {
      final parsed = await _scanner.captureAndProcess(_priceOcr.scanImageFile);
      if (!mounted) {
        return;
      }
      if (parsed == null || parsed.isEmpty) {
        setState(
          () => _statusMessage =
              "Couldn't read a price — enter it manually, or try again.",
        );
        return;
      }
      setState(() {
        if (parsed.totalPrice != null) {
          _totalController.text = parsed.totalPrice!.toStringAsFixed(2);
        }
        if (parsed.unitPrice != null) {
          _unitPriceController.text = parsed.unitPrice!.toStringAsFixed(2);
        }
        if (parsed.unitLabel != null) {
          _unitLabelController.text = parsed.unitLabel!;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _save() async {
    final total = double.tryParse(_totalController.text.trim());
    final unitPrice = double.tryParse(_unitPriceController.text.trim());
    final unitLabel = _unitLabelController.text.trim();
    await widget.basketService.setPrice(
      widget.entry,
      totalPrice: total,
      unitPrice: unitPrice,
      unitLabel: (unitPrice != null && unitLabel.isNotEmpty)
          ? unitLabel
          : null,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _scanner.controller;
    return Scaffold(
      appBar: AppBar(title: Text('Price: ${widget.entry.productName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 220,
            child: controller != null && controller.value.isInitialized
                ? CameraPreview(controller)
                : Center(child: Text(_statusMessage ?? 'Starting camera…')),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isBusy ? null : _scanPriceTag,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_isBusy ? 'Scanning…' : 'Scan price tag'),
          ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_statusMessage!),
            ),
          const Divider(height: 32),
          Text('Total price', style: Theme.of(context).textTheme.labelLarge),
          TextField(
            controller: _totalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
          ),
          const SizedBox(height: 16),
          Text(
            'Per-unit price (optional)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _unitPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _unitLabelController,
                  decoration: const InputDecoration(hintText: 'lb'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
