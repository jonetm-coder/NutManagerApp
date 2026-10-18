import '../data/database.dart';
import 'barcode_lookup_service.dart';
import 'product_lookup_service.dart';

/// Which tier of [ProductResolutionService.resolve]'s waterfall actually
/// identified a product.
///
/// UREQS: PLOOKUP-2
enum ResolutionSource {
  /// Already in the local shared catalog (the common case).
  localCatalog,

  /// Not in the catalog, but this household has bought it before (any
  /// list, active or archived).
  history,

  /// Not known locally at all; found via an external open product
  /// database.
  external,
}

/// A product identified by [ProductResolutionService.resolve], regardless
/// of which tier found it.
///
/// UREQS: PLOOKUP-2
class ResolvedProduct {
  /// Creates a resolved product.
  ///
  /// UREQS: PLOOKUP-2
  const ResolvedProduct({
    required this.name,
    required this.barcode,
    required this.category,
    required this.source,
  });

  /// The product's name.
  ///
  /// UREQS: PLOOKUP-2
  final String name;

  /// The scanned barcode.
  ///
  /// UREQS: PLOOKUP-2
  final String barcode;

  /// A coarse category — `'other'` for anything not already in the local
  /// catalog with a real category, since neither history nor the external
  /// lookup gives us one.
  ///
  /// UREQS: PLOOKUP-2
  final String category;

  /// Which tier resolved it.
  ///
  /// UREQS: PLOOKUP-2
  final ResolutionSource source;
}

/// Identifies a scanned barcode outside the context of any specific
/// shopping list (the "scan to add from home" flow) by trying, in order:
///
/// 1. The local shared catalog (same as in-store scanning, [BarcodeLookupService]).
/// 2. Any historical basket entry — on *any* list, active or archived —
///    that has this barcode. Finding one here means the household has
///    bought this exact product before, even though it never made it into
///    the shared catalog; the mapping is promoted into the catalog so
///    future lookups (by this household or, once NutCache exists, others)
///    skip straight to tier 1.
/// 3. [ProductLookupService]'s external by-barcode lookup, the same
///    deliberate internet-direct-from-phone stopgap documented there and
///    in docs/nutcache_migration_debt.md.
///
/// If all three miss, `resolve` returns `null` and the caller falls
/// through to manual entry — the same SCAN-8 pattern used when an
/// in-store scan isn't in the catalog.
///
/// UREQS: PLOOKUP-2
class ProductResolutionService {
  /// Creates the service from its three tiers' dependencies.
  ///
  /// UREQS: PLOOKUP-2
  ProductResolutionService(
    this._database,
    this._barcodeLookup,
    this._productLookup,
  );

  final AppDatabase _database;
  final BarcodeLookupService _barcodeLookup;
  final ProductLookupService _productLookup;

  /// Resolves [barcode] through the waterfall described on this class.
  ///
  /// UREQS: PLOOKUP-2
  Future<ResolvedProduct?> resolve(String barcode) async {
    final catalogEntry = await _barcodeLookup.lookup(barcode);
    if (catalogEntry != null) {
      return ResolvedProduct(
        name: catalogEntry.name,
        barcode: barcode,
        category: catalogEntry.category,
        source: ResolutionSource.localCatalog,
      );
    }

    final historicalMatches = await (_database.select(
      _database.basketEntries,
    )..where((row) => row.barcode.isIn(BarcodeLookupService.variantsOf(barcode)))).get();
    final historical = historicalMatches.isEmpty ? null : historicalMatches.first;
    if (historical != null) {
      await _promoteToCatalog(barcode, historical.productName);
      return ResolvedProduct(
        name: historical.productName,
        barcode: barcode,
        category: 'other',
        source: ResolutionSource.history,
      );
    }

    final external = await _productLookup.lookupByBarcode(barcode);
    if (external != null) {
      await _promoteToCatalog(barcode, external.name);
      return ResolvedProduct(
        name: external.name,
        barcode: barcode,
        category: 'other',
        source: ResolutionSource.external,
      );
    }

    return null;
  }

  Future<void> _promoteToCatalog(String barcode, String name) {
    return _database
        .into(_database.catalogEntries)
        .insertOnConflictUpdate(
          CatalogEntriesCompanion.insert(
            barcode: barcode,
            name: name,
            category: 'other',
          ),
        );
  }
}
