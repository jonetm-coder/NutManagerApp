import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A price reading parsed from a shelf tag/price label — a starting point
/// for the user to confirm or correct, never saved directly (PRICE-1,
/// PRICE-2, PRICE-10).
///
/// UREQS: PRICE-1, PRICE-10
class ParsedPrice {
  /// Creates a parsed price. All fields are nullable since a given label
  /// might show only a total, only a per-unit price, or (common for
  /// weighed items like meat) both.
  ///
  /// UREQS: PRICE-1, PRICE-10
  const ParsedPrice({this.totalPrice, this.unitPrice, this.unitLabel});

  /// The flat total price found, if any.
  ///
  /// UREQS: PRICE-1
  final double? totalPrice;

  /// The per-unit price found, if any (e.g. the `5.99` in "$5.99/lb").
  ///
  /// UREQS: PRICE-10
  final double? unitPrice;

  /// The unit [unitPrice] is in (e.g. "lb"), normalized to a short form.
  /// `null` whenever [unitPrice] is `null`.
  ///
  /// UREQS: PRICE-10
  final String? unitLabel;

  /// Whether nothing at all was found — callers should fall back to
  /// showing empty, user-editable fields rather than an error.
  ///
  /// UREQS: PRICE-2
  bool get isEmpty => totalPrice == null && unitPrice == null;
}

/// Reads a price tag/shelf label via on-device OCR (ML Kit text
/// recognition, per ADR 0003) and heuristically parses out a total and/or
/// per-unit price (PRICE-10).
///
/// The parser ([parseText]) is intentionally separated from the OCR call
/// ([scanImageFile]) so it can be unit-tested directly against known text
/// without needing a camera or an image file — the OCR step itself is
/// exercised the same way AT1.2 exercises barcode decoding, via an
/// on-device integration test against fixture images, not here.
///
/// UREQS: PRICE-1, PRICE-10
class PriceOcrService {
  /// Creates the service.
  ///
  /// UREQS: PRICE-1
  PriceOcrService() : _recognizer = TextRecognizer();

  final TextRecognizer _recognizer;

  /// Runs OCR on the image at [path] and parses the result. Returns
  /// [ParsedPrice.isEmpty] (not an error) if nothing recognizable was
  /// found — the price-entry screen shows the fields empty either way,
  /// for manual entry (PRICE-2).
  ///
  /// UREQS: PRICE-1
  Future<ParsedPrice> scanImageFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizedText = await _recognizer.processImage(inputImage);
    return parseText(recognizedText.text);
  }

  /// Parses dollar amounts out of [text], classifying each as a per-unit
  /// price (followed by a unit marker like "/lb" or "per lb") or a flat
  /// total otherwise. Takes the first match of each kind — this is a
  /// heuristic, not a guarantee of correctness, which is exactly why its
  /// output is always shown for user confirmation rather than saved
  /// directly.
  ///
  /// UREQS: PRICE-10
  ParsedPrice parseText(String text) {
    final matches = _pricePattern.allMatches(text);

    double? unitPrice;
    String? unitLabel;
    double? totalPrice;

    for (final match in matches) {
      final amount = double.tryParse(match.group(1) ?? '');
      if (amount == null) {
        continue;
      }
      final unitWord = match.group(2);
      if (unitWord != null) {
        unitPrice ??= amount;
        unitLabel ??= _normalizeUnit(unitWord);
      } else {
        totalPrice ??= amount;
      }
    }

    return ParsedPrice(
      totalPrice: totalPrice,
      unitPrice: unitPrice,
      unitLabel: unitLabel,
    );
  }

  /// Releases the ML Kit text recognizer.
  ///
  /// UREQS: PRICE-1
  Future<void> dispose() => _recognizer.close();

  static final RegExp _pricePattern = RegExp(
    r'\$?\s*(\d+\.\d{2})(?:\s*(?:/|per\s+)\s*(lb|lbs|pound|pounds|oz|ounce|ounces|ea|each|kg|g)\b)?',
    caseSensitive: false,
  );

  static String _normalizeUnit(String raw) {
    switch (raw.toLowerCase()) {
      case 'lbs':
      case 'pound':
      case 'pounds':
        return 'lb';
      case 'ounce':
      case 'ounces':
        return 'oz';
      case 'each':
        return 'ea';
      default:
        return raw.toLowerCase();
    }
  }
}
