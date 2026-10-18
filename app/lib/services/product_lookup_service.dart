import 'dart:convert';

import 'package:http/http.dart' as http;

/// A candidate product found in an external open product database.
///
/// UREQS: PLOOKUP-1, PLOOKUP-2
class ExternalProductCandidate {
  /// Creates a candidate.
  ///
  /// UREQS: PLOOKUP-1, PLOOKUP-2
  const ExternalProductCandidate({
    required this.barcode,
    required this.name,
    this.brand,
  });

  /// The product's barcode.
  ///
  /// UREQS: PLOOKUP-1, PLOOKUP-2
  final String barcode;

  /// The product's name.
  ///
  /// UREQS: PLOOKUP-1, PLOOKUP-2
  final String name;

  /// The product's brand, if known.
  ///
  /// UREQS: PLOOKUP-1, PLOOKUP-2
  final String? brand;
}

/// Looks up products in external open product databases — Open Food Facts
/// (primary; no API key required) and UPCitemdb (secondary, best-effort:
/// its free trial tier is rate-limited and may simply return nothing under
/// load, which this service treats as "no result" rather than an error).
///
/// **This queries the internet directly from the phone**, which is a
/// deliberate interim choice, not the long-term architecture: ADR 0012
/// designed the shared barcode database to be built and maintained
/// centrally via NutCache, bootstrapped from sources like this one and
/// crowdsourced from there — not queried live, per-device, by every
/// household independently. See docs/nutcache_migration_debt.md
/// (MIGRATE-1) for what moving this to NutCache would require.
///
/// UREQS: PLOOKUP-1, PLOOKUP-2
class ProductLookupService {
  /// Creates the service. [client] is injectable for testing; production
  /// code omits it and gets a real [http.Client].
  ///
  /// UREQS: PLOOKUP-1, PLOOKUP-2
  ProductLookupService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // The legacy `world.openfoodfacts.org/cgi/search.pl` CGI endpoint this
  // used to call now returns HTTP 503 for every request (confirmed via a
  // direct call, not an assumption) — Open Food Facts migrated full-text
  // search to this Elasticsearch-backed API. Every by-name search was
  // silently finding nothing as a result (searchByName's error handling
  // swallows the failure, by design, so there was no crash — just a quiet,
  // total miss for every product).
  static final Uri _openFoodFactsSearchUri = Uri.parse(
    'https://search.openfoodfacts.org/search',
  );

  static Uri _openFoodFactsProductUri(String barcode) => Uri.parse(
    'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
  );

  static Uri _upcItemDbLookupUri(String barcode) => Uri.parse(
    'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode',
  );

  /// Searches by product name (e.g. "Milk") — used by "Check Products"
  /// (PLOOKUP-1) to find barcode candidates for each list item before a
  /// trip. Network/parse failures are swallowed and return an empty list;
  /// this is a best-effort enhancement, not something that should ever
  /// block or crash the list screen.
  ///
  /// UREQS: PLOOKUP-1
  Future<List<ExternalProductCandidate>> searchByName(
    String name, {
    int limit = 10,
  }) async {
    try {
      final uri = _openFoodFactsSearchUri.replace(
        queryParameters: {
          'q': name,
          'page_size': '$limit',
          'fields': 'code,product_name,brands',
        },
      );
      final response = await _client
          .get(uri, headers: _requestHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return const [];
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final hits = decoded['hits'] as List<dynamic>? ?? const [];
      return hits
          .map(_candidateFromOpenFoodFactsJson)
          .whereType<ExternalProductCandidate>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Looks up a single barcode directly — used by the scan-to-add
  /// resolution waterfall's last resort (PLOOKUP-2), once local and
  /// historical lookups have both missed. Tries Open Food Facts first,
  /// then UPCitemdb; returns `null` if neither has it (or on any
  /// network/parse failure), never throws.
  ///
  /// UREQS: PLOOKUP-2
  Future<ExternalProductCandidate?> lookupByBarcode(String barcode) async {
    final fromOpenFoodFacts = await _lookupOpenFoodFacts(barcode);
    if (fromOpenFoodFacts != null) {
      return fromOpenFoodFacts;
    }
    return _lookupUpcItemDb(barcode);
  }

  Future<ExternalProductCandidate?> _lookupOpenFoodFacts(
    String barcode,
  ) async {
    try {
      final response = await _client
          .get(_openFoodFactsProductUri(barcode), headers: _requestHeaders)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] != 1) {
        return null;
      }
      final product = decoded['product'] as Map<String, dynamic>?;
      if (product == null) {
        return null;
      }
      return _candidateFromOpenFoodFactsJson(product);
    } catch (_) {
      return null;
    }
  }

  Future<ExternalProductCandidate?> _lookupUpcItemDb(String barcode) async {
    try {
      final response = await _client
          .get(_upcItemDbLookupUri(barcode))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items = decoded['items'] as List<dynamic>? ?? const [];
      if (items.isEmpty) {
        return null;
      }
      final item = items.first as Map<String, dynamic>;
      final title = item['title'] as String?;
      if (title == null || title.isEmpty) {
        return null;
      }
      return ExternalProductCandidate(
        barcode: barcode,
        name: title,
        brand: item['brand'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  // Shared by the by-name search (search.openfoodfacts.org, where `brands`
  // is a JSON array) and the by-barcode product lookup
  // (world.openfoodfacts.org/api/v2, where `brands` is a single
  // comma-separated string) — two different Open Food Facts APIs with two
  // different shapes for the same logical field, so both are handled here.
  ExternalProductCandidate? _candidateFromOpenFoodFactsJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final barcode = json['code'] as String?;
    final name = json['product_name'] as String?;
    if (barcode == null || barcode.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    return ExternalProductCandidate(
      barcode: barcode,
      name: name,
      brand: _firstBrand(json['brands']),
    );
  }

  String? _firstBrand(dynamic brands) {
    if (brands is List) {
      return brands.isEmpty ? null : brands.first.toString().trim();
    }
    if (brands is String && brands.isNotEmpty) {
      return brands.split(',').first.trim();
    }
    return null;
  }

  static const Map<String, String> _requestHeaders = {
    // Open Food Facts asks API consumers to identify themselves.
    'User-Agent': 'NutManagerApp - Android - Phase1 - dev',
  };
}
