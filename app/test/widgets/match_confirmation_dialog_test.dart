import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/screens/match_confirmation_dialog.dart';
import 'package:nut_manager_app/services/matching_service.dart';

ShoppingListItem _item(int id, String name) {
  return ShoppingListItem(
    id: id,
    listId: 1,
    name: name,
    category: 'dairy',
    quantity: 1,
    status: ListItemStatus.pending,
  );
}

/// Pumps the dialog under a button that opens it and taps the button, so
/// the dialog is showing by the time this returns. [onResult] is called
/// once the dialog is eventually popped (after the test interacts with
/// it), with whatever it was popped with.
Future<void> _openDialog(
  WidgetTester tester, {
  required List<MatchCandidate> candidates,
  required List<ShoppingListItem> allPendingItems,
  required void Function(ShoppingListItem?) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final result = await showDialog<ShoppingListItem>(
              context: context,
              builder: (context) => MatchConfirmationDialog(
                productName: 'Whole Milk, 1 Gal',
                candidates: candidates,
                allPendingItems: allPendingItems,
              ),
            );
            onResult(result);
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  // AT1.4 (widget-test portion): the confirmation dialog shown for an
  // ambiguous match (LIST-3). Leads with a one-tap suggestion (the
  // best-scoring candidate) rather than dumping every candidate up front;
  // "Other" reveals the full pending-item list only when the suggestion
  // is wrong. Reaching this dialog via a real camera scan is Stage 2 —
  // these tests pump it directly with a fixed candidate set.
  group('MatchConfirmationDialog', () {
    testWidgets(
      'suggests the best-scoring candidate by name and confirms it with '
      'one tap, without ever showing the full list',
      (tester) async {
        final candidates = [
          MatchCandidate(_item(1, 'Whole Milk'), 1.0),
          MatchCandidate(_item(2, 'Milk'), 0.5),
        ];
        final allPendingItems = [
          _item(1, 'Whole Milk'),
          _item(2, 'Milk'),
          _item(3, 'Eggs'),
        ];

        ShoppingListItem? result;
        await _openDialog(
          tester,
          candidates: candidates,
          allPendingItems: allPendingItems,
          onResult: (r) => result = r,
        );

        expect(find.text('This looks like "Whole Milk" on your list.'), findsOneWidget);
        expect(find.text('Eggs'), findsNothing);
        expect(find.text('Milk'), findsNothing);

        await tester.tap(find.text("Yes, that's it"));
        await tester.pumpAndSettle();

        expect(result?.id, 1);
      },
    );

    testWidgets(
      '"Other" reveals the full pending-item list (not just the scored '
      'candidates), and tapping an item there returns it',
      (tester) async {
        final candidates = [MatchCandidate(_item(1, 'Whole Milk'), 1.0)];
        final allPendingItems = [
          _item(1, 'Whole Milk'),
          _item(2, 'Milk'),
          _item(3, 'Eggs'),
        ];

        ShoppingListItem? result;
        await _openDialog(
          tester,
          candidates: candidates,
          allPendingItems: allPendingItems,
          onResult: (r) => result = r,
        );

        await tester.tap(find.text('Other'));
        await tester.pumpAndSettle();

        expect(find.text('Whole Milk'), findsOneWidget);
        expect(find.text('Milk'), findsOneWidget);
        expect(find.text('Eggs'), findsOneWidget);
        expect(find.text('None of these'), findsOneWidget);

        await tester.tap(find.text('Eggs'));
        await tester.pumpAndSettle();

        expect(result?.id, 3);
      },
    );

    testWidgets(
      '"None of these" (reached via "Other") dismisses with no selection',
      (tester) async {
        final candidates = [MatchCandidate(_item(1, 'Whole Milk'), 1.0)];
        final allPendingItems = [_item(1, 'Whole Milk')];

        ShoppingListItem? result = _item(999, 'sentinel');
        await _openDialog(
          tester,
          candidates: candidates,
          allPendingItems: allPendingItems,
          onResult: (r) => result = r,
        );

        await tester.tap(find.text('Other'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('None of these'));
        await tester.pumpAndSettle();

        expect(result, isNull);
      },
    );
  });
}
