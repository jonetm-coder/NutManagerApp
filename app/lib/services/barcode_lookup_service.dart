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
  /// Returns `null` if [barcode] is empty or not found — callers should
  /// treat `null` as "not found" and fall through to manual identification
  /// (SCAN-8), not as an error condition.
  ///
  /// This never makes a network call, satisfying the fully-offline
  /// identification requirement (SCAN-4) by construction.
  ///
  /// UREQS: SCAN-1, SCAN-4
  Future<CatalogEntry?> lookup(String barcode) {
    if (barcode.isEmpty) {
      return Future.value(null);
    }
    return (_database.select(
      _database.catalogEntries,
    )..where((row) => row.barcode.equals(barcode))).getSingleOrNull();
  }
}
