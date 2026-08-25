import '../data/database.dart';

/// A small, hand-picked abbreviation/synonym table bridging common shopping
/// list phrasing to catalog product naming (LIST-6).
///
/// This is intentionally tiny for Phase 1 — just enough to demonstrate the
/// mechanism with the seed data in `seed_catalog.dart`. The real system
/// (per ADR 0004) uses a much larger, crowdsourced synonym/category table;
/// this is not that, and shouldn't be grown ad hoc to "fix" real matching
/// gaps — that's what the later phase's real table is for.
///
/// UREQS: LIST-6
const Map<String, String> _synonymExpansions = {
  'choc': 'chocolate',
  'veggie': 'vegetable',
  'veggies': 'vegetables',
};

/// One candidate shopping-list-item match for a scanned/identified product,
/// with the score that produced it.
///
/// UREQS: LIST-2, LIST-3
class MatchCandidate {
  /// Creates a candidate with its [listItem] and [score].
  ///
  /// UREQS: LIST-2, LIST-3
  const MatchCandidate(this.listItem, this.score);

  /// The shopping list item this candidate refers to.
  ///
  /// UREQS: LIST-2
  final ShoppingListItem listItem;

  /// Match score in `[0.0, 1.0]`; higher is a better match. See
  /// [MatchingService] for how this is computed and interpreted.
  ///
  /// UREQS: LIST-2, LIST-3
  final double score;
}

/// How confidently a product was matched to the shopping list.
///
/// UREQS: LIST-2, LIST-3
enum MatchOutcome {
  /// Exactly one candidate clearly outscored the rest — safe to add to the
  /// basket without asking the user.
  confident,

  /// Multiple candidates are plausible (or the best one isn't clearly
  /// better than the next), or the only candidate(s) are a weak
  /// category-only match — the user must be asked (LIST-3).
  ambiguous,

  /// No shopping list item is a plausible match at all.
  none,
}

/// The result of matching a product against the current shopping list.
///
/// UREQS: LIST-2, LIST-3
class MatchResult {
  /// Creates a result. [candidates] is sorted by descending score and is
  /// empty when [outcome] is [MatchOutcome.none].
  ///
  /// UREQS: LIST-2, LIST-3
  const MatchResult(this.outcome, this.candidates);

  /// How confidently the match was made.
  ///
  /// UREQS: LIST-2, LIST-3
  final MatchOutcome outcome;

  /// Candidate list items, best match first.
  ///
  /// UREQS: LIST-2, LIST-3
  final List<MatchCandidate> candidates;
}

/// Matches an identified product against the household's pending shopping
/// list items.
///
/// Scoring (Phase 1; intentionally simple, documented here rather than
/// buried in the implementation since the exact thresholds are a judgment
/// call worth being able to revisit):
/// - `1.0` for an exact normalized-name match.
/// - Jaccard token overlap (after synonym expansion, [_synonymExpansions])
///   when there's any token overlap at all.
/// - A fixed weak score of `0.3` when there's no token overlap but the
///   category matches (the category/synonym fallback, LIST-6).
/// - `0.0` (excluded from candidates) otherwise.
///
/// A single candidate scoring at least [confidentThreshold], with no other
/// candidate within [ambiguityMargin] of it, is a confident match
/// (LIST-2). Otherwise, any candidate with a nonzero score makes the
/// result ambiguous (LIST-3) rather than silently picking one.
///
/// UREQS: LIST-2, LIST-3, LIST-6
class MatchingService {
  /// Minimum score for a single best candidate to be auto-matched without
  /// user confirmation.
  ///
  /// UREQS: LIST-2
  static const double confidentThreshold = 0.6;

  /// If the second-best candidate's score is within this margin of the
  /// best one, treat the match as ambiguous even if the best score alone
  /// would clear [confidentThreshold].
  ///
  /// UREQS: LIST-3
  static const double ambiguityMargin = 0.15;

  static const double _categoryFallbackScore = 0.3;

  /// Matches [productName]/[productCategory] against [pendingItems].
  ///
  /// UREQS: LIST-2, LIST-3, LIST-6
  MatchResult match({
    required String productName,
    required String productCategory,
    required List<ShoppingListItem> pendingItems,
  }) {
    final productTokens = _tokenize(productName);
    final scored = <MatchCandidate>[];

    for (final item in pendingItems) {
      final score = _score(
        itemName: item.name,
        itemCategory: item.category,
        productTokens: productTokens,
        productCategory: productCategory,
      );
      if (score > 0) {
        scored.add(MatchCandidate(item, score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return const MatchResult(MatchOutcome.none, []);
    }

    final best = scored.first;
    final secondBest = scored.length > 1 ? scored[1] : null;
    final isConfident =
        best.score >= confidentThreshold &&
        (secondBest == null ||
            (best.score - secondBest.score) > ambiguityMargin);

    return MatchResult(
      isConfident ? MatchOutcome.confident : MatchOutcome.ambiguous,
      scored,
    );
  }

  double _score({
    required String itemName,
    required String itemCategory,
    required Set<String> productTokens,
    required String productCategory,
  }) {
    final itemTokens = _tokenize(itemName);

    if (_setEquals(itemTokens, productTokens)) {
      return 1.0;
    }

    final intersection = itemTokens.intersection(productTokens);
    if (intersection.isNotEmpty) {
      final union = itemTokens.union(productTokens);
      return intersection.length / union.length;
    }

    if (_normalizeCategory(itemCategory) ==
        _normalizeCategory(productCategory)) {
      return _categoryFallbackScore;
    }

    return 0.0;
  }

  Set<String> _tokenize(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9%\s]'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return {};
    }
    return normalized
        .split(RegExp(r'\s+'))
        .map((token) => _synonymExpansions[token] ?? token)
        .toSet();
  }

  String _normalizeCategory(String category) => category.trim().toLowerCase();
}

// Set equality helper (avoids pulling in `package:collection` for one
// comparison). Private: an implementation detail of the scoring above, not
// part of this file's public API.
bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
