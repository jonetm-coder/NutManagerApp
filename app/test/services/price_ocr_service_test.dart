import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/services/price_ocr_service.dart';

void main() {
  // PRICE-10: parseText() is the pure, camera-free half of PriceOcrService —
  // OCR itself is only verifiable on-device, so this locks in the parsing
  // heuristic directly.
  group('PriceOcrService.parseText', () {
    final service = PriceOcrService();

    test('a flat total with no unit marker is a total price', () {
      final result = service.parseText('Sale Price \$3.99');

      expect(result.totalPrice, 3.99);
      expect(result.unitPrice, isNull);
      expect(result.unitLabel, isNull);
      expect(result.isEmpty, isFalse);
    });

    test('a price followed by "/lb" is a per-unit price, not a total', () {
      final result = service.parseText('Ground Beef \$5.99/lb');

      expect(result.unitPrice, 5.99);
      expect(result.unitLabel, 'lb');
      expect(result.totalPrice, isNull);
    });

    test('a tag with both a per-unit and a total price captures both', () {
      final result = service.parseText('\$5.99/lb\nTotal \$12.99');

      expect(result.unitPrice, 5.99);
      expect(result.unitLabel, 'lb');
      expect(result.totalPrice, 12.99);
    });

    test('unit words normalize to their short form', () {
      expect(service.parseText('\$2.50 per pound').unitLabel, 'lb');
      expect(service.parseText('\$0.99/OZ').unitLabel, 'oz');
      expect(service.parseText('\$1.25/EACH').unitLabel, 'ea');
    });

    test('only the first match of each kind is kept', () {
      final result = service.parseText('\$3.99 \$4.99');

      expect(result.totalPrice, 3.99);
    });

    test('text with no recognizable price is empty, not an error', () {
      final result = service.parseText('Fresh Produce');

      expect(result.isEmpty, isTrue);
      expect(result.totalPrice, isNull);
      expect(result.unitPrice, isNull);
    });
  });
}
