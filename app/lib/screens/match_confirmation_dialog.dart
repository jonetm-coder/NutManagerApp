import 'package:flutter/material.dart';

import '../data/database.dart';
import '../services/matching_service.dart';

/// Shown when a matched product needs user confirmation before being added
/// to the basket: today, that's exclusively the LIST-3 ambiguous-candidate
/// case. SCAN-7 ("low confidence" identification) is documented here too
/// because it will reuse this same dialog once Phase 2's OCR/
/// image-classification paths introduce a real, non-binary confidence
/// score to be low about — barcode-only lookup (Phase 1) is a deterministic
/// hit/miss, so there isn't yet a genuine SCAN-7 case distinct from LIST-3.
/// See docs/development-plan.md's Phase 1 section.
///
/// Leads with a single suggestion — [candidates]' best-scoring match — for
/// a one-tap confirmation, since most products match by name clearly
/// enough that showing every candidate up front is unnecessary friction.
/// "Other" reveals the full pending-item list ([allPendingItems], not just
/// the scored candidates) only if the suggestion is wrong.
///
/// UREQS: LIST-3, SCAN-7
class MatchConfirmationDialog extends StatefulWidget {
  /// Creates the dialog for [productName]'s ambiguous [candidates], with
  /// [allPendingItems] as the fallback full list behind "Other".
  ///
  /// UREQS: LIST-3
  const MatchConfirmationDialog({
    super.key,
    required this.productName,
    required this.candidates,
    required this.allPendingItems,
  });

  /// The identified product's name, shown as context in the dialog title.
  ///
  /// UREQS: LIST-3
  final String productName;

  /// Candidate shopping list items, best match first. The first entry is
  /// shown as the one-tap suggestion.
  ///
  /// UREQS: LIST-3
  final List<MatchCandidate> candidates;

  /// Every pending item on the list, shown behind "Other" when the
  /// suggested candidate isn't the right one.
  ///
  /// UREQS: LIST-3
  final List<ShoppingListItem> allPendingItems;

  @override
  State<MatchConfirmationDialog> createState() =>
      _MatchConfirmationDialogState();
}

class _MatchConfirmationDialogState extends State<MatchConfirmationDialog> {
  bool _showingFullList = false;

  @override
  Widget build(BuildContext context) {
    if (_showingFullList) {
      return AlertDialog(
        title: Text('Which item is "${widget.productName}"?'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final item in widget.allPendingItems)
                ListTile(
                  title: Text(item.name),
                  onTap: () => Navigator.of(context).pop(item),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('None of these'),
          ),
        ],
      );
    }

    final suggestion = widget.candidates.first.listItem;
    return AlertDialog(
      title: Text('Add "${widget.productName}"'),
      content: Text('This looks like "${suggestion.name}" on your list.'),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showingFullList = true),
          child: const Text('Other'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(suggestion),
          child: const Text("Yes, that's it"),
        ),
      ],
    );
  }
}
