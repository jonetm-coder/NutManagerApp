import '../data/database.dart';

/// Resolves a decoded barcode value to a catalog product.
///
/// Phase 1 looks this up against the local seed catalog only
/// ([seedCatalog]); a later phase replaces/extends this with the shared
/// barcode database from ADR 0012.
///
/// UREQS: SCAN-1, SCAN-4
class BarcodeLookupService {
  /// Creates a lookup service backed by [database].
  ///
  /// UREQS: SCAN-1
  BarcodeLookupService(this._database);

  final AppDatabase _database;

  /// Looks up [barcode] in the local catalog.
  ///
  /// Matches against [variantsOf], not just the literal scanned string:
  /// ML Kit's scanner and Open Food Facts' stored `code` field don't
  /// consistently agree on whether a UPC-A code is 12 digits or
  /// zero-padded to 13 (EAN-13), so a real product whose barcode was
  /// cached in one form could otherwise go unmatched when scanned and
  /// decoded in the other — a real bug found via a user report where a
  /// product's barcode had been found by [ProductLookupService] (so a
  /// candidate *was* in the catalog) but still wasn't recognized on scan.
  ///
  /// Returns `null` if [barcode] is empty or not found — callers should
  /// treat `null` as "not found" and fall through to manual identification
  /// (SCAN-8), not as an error condition.
  ///
  /// This never makes a network call, satisfying the fully-offline
  /// identification requirement (SCAN-4) by construction.
  ///
  /// UREQS: SCAN-1, SCAN-4
  Future<CatalogEntry?> lookup(String barcode) async {
    if (barcode.isEmpty) {
      return null;
    }
    final matches = await (_database.select(
      _database.catalogEntries,
    )..where((row) => row.barcode.isIn(variantsOf(barcode)))).get();
    return matches.isEmpty ? null : matches.first;
  }

  /// The set of barcode strings that plausibly represent the same product
  /// as [barcode]: itself, plus — when it looks like a UPC-A/EAN-13 pair —
  /// the zero-padded or zero-stripped counterpart. A 12-digit code gains
  /// a leading-zero 13-digit variant; a 13-digit code starting with '0'
  /// gains its 12-digit form. Anything else (a genuinely different-length
  /// or non-UPC-A-compatible EAN-13 code) is returned as-is.
  ///
  /// UREQS: SCAN-1
  static Set<String> variantsOf(String barcode) {
    final variants = {barcode};
    if (barcode.length == 12) {
      variants.add('0$barcode');
    } else if (barcode.length == 13 && barcode.startsWith('0')) {
      variants.add(barcode.substring(1));
    }
    return variants;
  }
}
