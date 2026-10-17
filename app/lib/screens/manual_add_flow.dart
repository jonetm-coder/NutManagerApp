import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/basket_service.dart';
import '../services/matching_service.dart';
import 'manual_add_item_dialog.dart';
import 'match_confirmation_dialog.dart';

/// Shows the manual-add dialog (LIST-5) and, if the user enters a name,
/// runs it through [MatchingService] against the current pending list
/// items before adding it to [basketService]'s **basket** — rather than
/// always adding an unlinked entry.
///
/// A manually-typed name can confidently or ambiguously match the list
/// (LIST-2/LIST-3) exactly like a scanned product does. Skipping this step
/// was a real Phase 1 bug: typing "milk" for an unrecognized barcode never
/// matched the list's "Milk" item — not because matching is
/// case-sensitive (it isn't; see [MatchingService]), but because manual
/// entry never attempted to match at all. Shared here so both the
/// shopping-list screen's "Add to Basket" button and the scan screen's
/// not-found-in-catalog fallback (SCAN-8) go through the same logic
/// rather than duplicating (and risking re-diverging) it.
///
/// This adds to the **basket** (something the user is holding/picked up),
/// not the **list** (something planned ahead of time) — see
/// [showAddPlannedItemFlow] for that.
///
/// UREQS: LIST-2, LIST-3, LIST-5, SCAN-8
Future<void> showManualAddFlow({
  required BuildContext context,
  required BasketService basketService,
}) async {
  final entered = await showDialog<(String, int)>(
    context: context,
    builder: (context) =>
        const ManualAddItemDialog(title: 'Add to basket'),
  );
  if (entered == null) {
    return;
  }
  final (name, quantity) = entered;

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

  await basketService.addManually(
    name,
    matchedItem: matchedItem,
    quantity: quantity,
  );
}

/// Shows the manual-add dialog and, if the user enters a name, adds it to
/// [basketService]'s **list** as a planned item (LSTORG-2) — e.g. entered
/// at home before a trip. No matching is involved: this creates a new
/// planned item outright, rather than reconciling against existing ones
/// (that's what scanning/[showManualAddFlow] do against *this* list).
///
/// UREQS: LSTORG-2
Future<void> showAddPlannedItemFlow({
  required BuildContext context,
  required BasketService basketService,
}) async {
  final entered = await showDialog<(String, int)>(
    context: context,
    builder: (context) => const ManualAddItemDialog(title: 'Add to list'),
  );
  if (entered == null) {
    return;
  }
  final (name, quantity) = entered;
  await basketService.addPlannedItem(name, quantity: quantity);
}
