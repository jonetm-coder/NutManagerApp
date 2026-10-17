import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/basket_service.dart';
import '../services/matching_service.dart';
import 'manual_add_item_dialog.dart';
import 'match_confirmation_dialog.dart';

/// Shows the manual-add dialog (LIST-5) and, if the user enters a name,
/// runs it through [MatchingService] against the current pending list
/// items before adding it to [basketService] — rather than always adding
/// an unlinked entry.
///
/// A manually-typed name can confidently or ambiguously match the list
/// (LIST-2/LIST-3) exactly like a scanned product does. Skipping this step
/// was a real Phase 1 bug: typing "milk" for an unrecognized barcode never
/// matched the list's "Milk" item — not because matching is
/// case-sensitive (it isn't; see [MatchingService]), but because manual
/// entry never attempted to match at all. Shared here so both the
/// shopping-list screen's "+" button and the scan screen's
/// not-found-in-catalog fallback (SCAN-8) go through the same logic
/// rather than duplicating (and risking re-diverging) it.
///
/// UREQS: LIST-2, LIST-3, LIST-5, SCAN-8
Future<void> showManualAddFlow({
  required BuildContext context,
  required BasketService basketService,
}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) => const ManualAddItemDialog(),
  );
  if (name == null) {
    return;
  }

  final result = MatchingService().match(
    productName: name,
    pendingItems: basketService.pendingItems,
  );

  ShoppingListItem? matchedItem;
  switch (result.outcome) {
    case MatchOutcome.confident:
      matchedItem = result.candidates.first.listItem;
    case MatchOutcome.ambiguous:
      if (!context.mounted) {
        return;
      }
      matchedItem = await showDialog<ShoppingListItem>(
        context: context,
        builder: (context) => MatchConfirmationDialog(
          productName: name,
          candidates: result.candidates,
        ),
      );
    case MatchOutcome.none:
      matchedItem = null;
  }

  await basketService.addManually(name, matchedItem: matchedItem);
}
