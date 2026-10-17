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
  /// category-only or fuzzy/misspelling match — the user must be asked
  /// (LIST-3).
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

/// Matches an identified (or manually-typed — see note below) product
/// against the household's pending shopping list items.
///
/// Scoring (Phase 1; intentionally simple, documented here rather than
/// buried in the implementation since the exact thresholds are a judgment
/// call worth being able to revisit). Normalization (case-folding,
/// punctuation stripping) is applied before every comparison below, so
/// matching is **not** case-sensitive at any stage — "milk" and "Milk" are
/// identical inputs to this engine:
/// - `1.0` for an exact normalized-name match.
/// - Jaccard token overlap (after synonym expansion, [_synonymExpansions])
///   when there's any token overlap at all.
/// - A fixed weak score of `0.3` when there's no token overlap but the
///   category matches (the category/synonym fallback, LIST-6) — only
///   applicable when [productCategory] is known.
/// - A fuzzy whole-string similarity (normalized Levenshtein distance),
///   when nothing above matched, for genuine misspellings (LIST-6) —
///   e.g. "Mufins" vs. "Muffins". This is deliberately capped below
///   [confidentThreshold] (see [_fuzzyMatchCap]): a fuzzy match is never
///   auto-applied, only ever surfaced for user confirmation (LIST-3),
///   since it's the least certain kind of match this engine makes.
/// - `0.0` (excluded from candidates) otherwise.
///
/// A single candidate scoring at least [confidentThreshold], with no other
/// candidate within [ambiguityMargin] of it, is a confident match
/// (LIST-2). Otherwise, any candidate with a nonzero score makes the
/// result ambiguous (LIST-3) rather than silently picking one.
///
/// **Always run typed/manual entries through this too.** [productCategory]
/// is nullable specifically so a manually-typed name (SCAN-8, with no
/// known category) can still be matched — skipping this engine for manual
/// entries was a real Phase 1 bug (a manually-typed "milk" never matched
/// the list's "Milk" item, not because matching is case-sensitive, but
/// because manual entry didn't call this engine at all).
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

  /// Minimum whole-string similarity (normalized Levenshtein) for a fuzzy
  /// match to be considered at all.
  static const double _fuzzyMatchMinSimilarity = 0.7;

  /// Score ceiling for a fuzzy-only match — kept below [confidentThreshold]
  /// so a misspelling can never auto-apply, only prompt for confirmation.
  static const double _fuzzyMatchCap = 0.5;

  /// Matches [productName]/[productCategory] against [pendingItems].
  /// [productCategory] may be `null` for a manually-typed entry with no
  /// known category — category-fallback scoring is simply skipped in
  /// that case, not treated as an error.
  ///
  /// UREQS: LIST-2, LIST-3, LIST-6
  MatchResult match({
    required String productName,
    String? productCategory,
    required List<ShoppingListItem> pendingItems,
  }) {
    final productTokens = _tokenize(productName);
    final scored = <MatchCandidate>[];

    for (final item in pendingItems) {
      final score = _score(
        itemName: item.name,
        itemCategory: item.category,
        productName: productName,
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
    required String productName,
    required Set<String> productTokens,
    String? productCategory,
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

    // Neither of these is a short-circuit return: a candidate can be both
    // in the right category *and* a plausible misspelling, and the higher
    // of the two signals is the more informative one to show the user,
    // not whichever happened to be checked first.
    var fallbackScore = 0.0;
    if (productCategory != null &&
        _normalizeCategory(itemCategory) ==
            _normalizeCategory(productCategory)) {
      fallbackScore = _categoryFallbackScore;
    }

    final fuzzy = _fuzzySimilarity(itemName, productName);
    if (fuzzy >= _fuzzyMatchMinSimilarity) {
      final cappedFuzzy = fuzzy < _fuzzyMatchCap ? fuzzy : _fuzzyMatchCap;
      if (cappedFuzzy > fallbackScore) {
        fallbackScore = cappedFuzzy;
      }
    }

    return fallbackScore;
  }

  Set<String> _tokenize(String text) {
    final normalized = _normalizeText(text);
    if (normalized.isEmpty) {
      return {};
    }
    return normalized
        .split(RegExp(r'\s+'))
        .map((token) => _synonymExpansions[token] ?? token)
        .toSet();
  }

  /// Case-folds and strips punctuation, without splitting into tokens —
  /// used for the fuzzy whole-string comparison, where token boundaries
  /// would throw away exactly the character-level information a
  /// misspelling check needs.
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9%\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeCategory(String category) => category.trim().toLowerCase();

  double _fuzzySimilarity(String a, String b) {
    final na = _normalizeText(a);
    final nb = _normalizeText(b);
    if (na.isEmpty || nb.isEmpty) {
      return 0.0;
    }
    final maxLen = na.length > nb.length ? na.length : nb.length;
    final distance = _levenshteinDistance(na, nb);
    return 1.0 - (distance / maxLen);
  }

  /// Classic dynamic-programming edit distance (single-row, no third-party
  /// dependency needed for one small computation).
  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    var previousRow = List<int>.generate(lb + 1, (j) => j);
    for (var i = 1; i <= la; i++) {
      final currentRow = List<int>.filled(lb + 1, 0);
      currentRow[0] = i;
      for (var j = 1; j <= lb; j++) {
        final substitutionCost = a[i - 1] == b[j - 1] ? 0 : 1;
        final deletion = previousRow[j] + 1;
        final insertion = currentRow[j - 1] + 1;
        final substitution = previousRow[j - 1] + substitutionCost;
        currentRow[j] = [
          deletion,
          insertion,
          substitution,
        ].reduce((x, y) => x < y ? x : y);
      }
      previousRow = currentRow;
    }
    return previousRow[lb];
  }
}

// Set equality helper (avoids pulling in `package:collection` for one
// comparison). Private: an implementation detail of the scoring above, not
// part of this file's public API.
bool _setEquals<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
