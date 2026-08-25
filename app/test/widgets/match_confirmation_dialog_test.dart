import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/screens/match_confirmation_dialog.dart';
import 'package:nut_manager_app/services/matching_service.dart';

ShoppingListItem _item(int id, String name) {
  return ShoppingListItem(
    id: id,
    name: name,
    category: 'dairy',
    status: ListItemStatus.pending,
  );
}

void main() {
  // AT1.4 (widget-test portion): the confirmation dialog shown for an
  // ambiguous match (LIST-3). Reaching this dialog via a real camera scan
  // is Stage 2 — this test pumps it directly with a fixed candidate set.
  group('MatchConfirmationDialog', () {
    testWidgets('lists every candidate and returns the tapped one', (
      tester,
    ) async {
      final candidates = [
        MatchCandidate(_item(1, 'Whole Milk'), 1.0),
        MatchCandidate(_item(2, 'Milk'), 0.5),
      ];
      ShoppingListItem? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShoppingListItem>(
                  context: context,
                  builder: (context) => MatchConfirmationDialog(
                    productName: 'Whole Milk, 1 Gal',
                    candidates: candidates,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Whole Milk'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('None of these'), findsOneWidget);

      await tester.tap(find.text('Whole Milk'));
      await tester.pumpAndSettle();

      expect(result?.id, 1);
    });

    testWidgets('"None of these" dismisses with no selection', (tester) async {
      final candidates = [MatchCandidate(_item(1, 'Whole Milk'), 1.0)];
      ShoppingListItem? result = _item(999, 'sentinel');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShoppingListItem>(
                  context: context,
                  builder: (context) => MatchConfirmationDialog(
                    productName: 'Whole Milk, 1 Gal',
                    candidates: candidates,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('None of these'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
