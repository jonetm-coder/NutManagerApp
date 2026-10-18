import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nut_manager_app/services/product_lookup_service.dart';

void main() {
  // PLOOKUP-1/PLOOKUP-2/PLOOKUP-3: locks in the actual request/response
  // contract against a mocked http.Client, rather than only testing the
  // error-swallowing behavior — this is a regression test for a real bug
  // where the by-name search endpoint had quietly started returning HTTP
  // 503 for every request (Open Food Facts retired the legacy
  // `cgi/search.pl` endpoint), and because ProductLookupService swallows
  // all network/parse failures by design, every lookup silently found
  // nothing with no error surfaced anywhere, for every product, not just
  // one. Asserting on the request URI here means a future endpoint change
  // breaks a test instead of silently degrading in production.
  group('ProductLookupService.searchByName', () {
    test('parses hits from the search-a-licious response shape', () async {
      Uri? requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'hits': [
              {
                'code': '0048121102081',
                'product_name': 'Thomas original english muffins',
                'brands': ['Thomas', 'Bimbo Bakeries Usa  Inc.'],
              },
            ],
          }),
          200,
        );
      });
      final service = ProductLookupService(client: client);

      final results = await service.searchByName("Thomas's English Muffins");

      expect(requestedUri?.host, 'search.openfoodfacts.org');
      expect(requestedUri?.queryParameters['q'], "Thomas's English Muffins");
      expect(results, hasLength(1));
      expect(results.single.barcode, '0048121102081');
      expect(results.single.name, 'Thomas original english muffins');
      expect(results.single.brand, 'Thomas');
    });

    test('a non-200 response (e.g. a dead/retired endpoint) returns an empty list, not an error', () async {
      final client = MockClient((request) async => http.Response('', 503));
      final service = ProductLookupService(client: client);

      final results = await service.searchByName('Milk');

      expect(results, isEmpty);
    });

    test('an HTML error page instead of JSON is treated as no results', () async {
      final client = MockClient(
        (request) async => http.Response('<!DOCTYPE html>...', 200),
      );
      final service = ProductLookupService(client: client);

      final results = await service.searchByName('Milk');

      expect(results, isEmpty);
    });
  });

  group('ProductLookupService.lookupByBarcode', () {
    test('parses a found product from the by-barcode endpoint (brands as a string)', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openfoodfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'code': '0048121102081',
                'product_name': 'English Muffins',
                'brands': 'Thomas',
              },
            }),
            200,
          );
        }
        return http.Response('', 404);
      });
      final service = ProductLookupService(client: client);

      final result = await service.lookupByBarcode('0048121102081');

      expect(result?.name, 'English Muffins');
      expect(result?.brand, 'Thomas');
    });

    test('falls back to UPCitemdb when Open Food Facts has no match', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openfoodfacts.org') {
          return http.Response(jsonEncode({'status': 0}), 200);
        }
        if (request.url.host == 'api.upcitemdb.com') {
          return http.Response(
            jsonEncode({
              'items': [
                {'title': 'Fallback Product', 'brand': 'Acme'},
              ],
            }),
            200,
          );
        }
        return http.Response('', 404);
      });
      final service = ProductLookupService(client: client);

      final result = await service.lookupByBarcode('000000000000');

      expect(result?.name, 'Fallback Product');
      expect(result?.brand, 'Acme');
    });

    test('returns null when neither source has the barcode', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openfoodfacts.org') {
          return http.Response(jsonEncode({'status': 0}), 200);
        }
        return http.Response(jsonEncode({'items': []}), 200);
      });
      final service = ProductLookupService(client: client);

      final result = await service.lookupByBarcode('000000000000');

      expect(result, isNull);
    });
  });
}
