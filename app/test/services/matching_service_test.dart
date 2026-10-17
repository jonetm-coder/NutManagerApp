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

    test('matching is not case-sensitive', () {
      final result = service.match(
        productName: 'milk',
        pendingItems: [_item(1, 'Milk', 'dairy')],
      );

      expect(result.outcome, MatchOutcome.confident);
      expect(result.candidates.single.score, 1.0);
    });

    test(
      'a null category (manual entry, SCAN-8) skips the category fallback '
      'without erroring, and still matches via token overlap',
      () {
        final result = service.match(
          productName: 'Panko Bread Crumbs',
          pendingItems: [_item(1, 'Panko Bread Crumbs', 'pantry')],
        );

        expect(result.outcome, MatchOutcome.confident);
      },
    );

    test(
      'a genuine misspelling fuzzy-matches but is always ambiguous, never '
      'confident (LIST-6) — the bug report this came from',
      () {
        // A single-word typo, deliberately: a multi-word phrase with one
        // misspelled word (e.g. "English Mufins" vs "English Muffins")
        // would already clear the confident threshold via ordinary Jaccard
        // token overlap on the other shared words, without ever
        // exercising the fuzzy path this test is actually checking. A
        // single word gives tokenize() zero token overlap (two entirely
        // different one-token sets), isolating the fuzzy comparison.
        final result = service.match(
          productName: 'Yogurt',
          pendingItems: [_item(1, 'Yogurrt', 'dairy')], // one extra "r"
        );

        expect(result.outcome, MatchOutcome.ambiguous);
        expect(result.candidates, hasLength(1));
        expect(
          result.candidates.single.score,
          lessThan(MatchingService.confidentThreshold),
        );
      },
    );

    test('a string too different to be a plausible misspelling is no match', () {
      final result = service.match(
        productName: 'Orange Juice',
        pendingItems: [_item(1, 'Panko Bread Crumbs', 'pantry')],
      );

      expect(result.outcome, MatchOutcome.none);
    });
  });
}
