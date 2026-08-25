import 'package:flutter/material.dart';

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
/// UREQS: LIST-3, SCAN-7
class MatchConfirmationDialog extends StatelessWidget {
  /// Creates the dialog for [productName]'s ambiguous [candidates].
  ///
  /// UREQS: LIST-3
  const MatchConfirmationDialog({
    super.key,
    required this.productName,
    required this.candidates,
  });

  /// The identified product's name, shown as context in the dialog title.
  ///
  /// UREQS: LIST-3
  final String productName;

  /// Candidate shopping list items to choose from, best match first.
  ///
  /// UREQS: LIST-3
  final List<MatchCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Which item is "$productName"?'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final candidate in candidates)
              ListTile(
                title: Text(candidate.listItem.name),
                onTap: () => Navigator.of(context).pop(candidate.listItem),
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
}
