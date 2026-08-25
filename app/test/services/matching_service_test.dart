import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/services/matching_service.dart';

ShoppingListItem _item(int id, String name, String category) {
  return ShoppingListItem(
    id: id,
    name: name,
    category: category,
    status: ListItemStatus.pending,
  );
}

void main() {
  // AT1.3: matching engine — exact match, synonym match (LIST-6), ambiguous
  // cases, category-only fallback, and no-match.
  group('MatchingService', () {
    final service = MatchingService();

    test('exact name match is confident', () {
      final result = service.match(
        productName: 'Cheerios Cereal',
        productCategory: 'cereal',
        pendingItems: [_item(1, 'Cheerios Cereal', 'cereal')],
      );

      expect(result.outcome, MatchOutcome.confident);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.first.listItem.id, 1);
      expect(result.candidates.first.score, 1.0);
    });

    test('synonym expansion bridges wording differences (LIST-6)', () {
      final result = service.match(
        productName: 'Chocolate Chip Cookies',
        productCategory: 'snacks',
        pendingItems: [_item(1, 'Choc Chip Cookies', 'snacks')],
      );

      expect(result.outcome, MatchOutcome.confident);
      expect(result.candidates.single.score, 1.0);
    });

    test(
      'a single weak candidate below the confident threshold is ambiguous',
      () {
        final result = service.match(
          productName: 'Whole Milk, 1 Gal',
          productCategory: 'dairy',
          pendingItems: [_item(1, 'Milk', 'dairy')],
        );

        expect(result.outcome, MatchOutcome.ambiguous);
        expect(result.candidates, hasLength(1));
        expect(
          result.candidates.first.score,
          lessThan(MatchingService.confidentThreshold),
        );
      },
    );

    test(
      'two high-scoring candidates within the ambiguity margin stay ambiguous',
      () {
        final result = service.match(
          productName: 'Whole Milk',
          productCategory: 'dairy',
          pendingItems: [
            _item(1, 'Whole Milk', 'dairy'),
            _item(2, 'Whole Milk', 'dairy'),
          ],
        );

        expect(result.outcome, MatchOutcome.ambiguous);
        expect(result.candidates, hasLength(2));
        expect(result.candidates[0].score, 1.0);
        expect(result.candidates[1].score, 1.0);
      },
    );

    test(
      'same-category, no token overlap produces a weak fallback match (LIST-6)',
      () {
        final result = service.match(
          productName: 'Ground Coffee, Medium Roast',
          productCategory: 'pantry',
          pendingItems: [_item(1, 'Creamy Peanut Butter', 'pantry')],
        );

        expect(result.outcome, MatchOutcome.ambiguous);
        expect(result.candidates.single.score, 0.3);
      },
    );

    test('no plausible candidate at all returns none', () {
      final result = service.match(
        productName: 'Roma Tomatoes',
        productCategory: 'produce',
        pendingItems: [_item(1, 'Ground Coffee, Medium Roast', 'pantry')],
      );

      expect(result.outcome, MatchOutcome.none);
      expect(result.candidates, isEmpty);
    });

    test('empty pending list returns none', () {
      final result = service.match(
        productName: 'Anything',
        productCategory: 'other',
        pendingItems: const [],
      );

      expect(result.outcome, MatchOutcome.none);
    });
  });
}
