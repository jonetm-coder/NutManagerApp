# ADR 0004: Product-to-Shopping-List Matching Strategy

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Once a product has been identified by the capture pipeline (ADR 0002) — as a UPC/EAN from a barcode, as OCR'd brand/name/size text, or as a predicted category from image classification — it must be matched against the user's shopping list. Shopping list items are largely free text, entered by the user or generated from recipes/nutrition plans (e.g., "milk", "2% milk", "whole milk 1 gal", "choc chip cookies"), and are not guaranteed to reference a specific catalog product or UPC.

This matching must run entirely on-device (no connectivity assumed in-store) and must handle ambiguity gracefully rather than silently guessing wrong, since an incorrect auto-match would be confusing and erode trust in the app.

## Decision

Use a **layered matching strategy**, attempted in order of specificity, with a confidence threshold that triggers user confirmation when no stage produces a clear match:

1. **Exact identifier match**: if the scanned product resolves to a UPC/EAN and a shopping list item is linked to that same catalog product ID (e.g., added via a prior scan or from a recipe with structured ingredients), match directly. Highest confidence, no confirmation needed.
2. **Normalized text match**: normalize both the scanned product's text (brand + name, from barcode-catalog lookup or OCR) and the shopping list item text (lowercase, strip punctuation/units, singularize, expand common abbreviations like "choc" → "chocolate") and compare using token overlap plus string-similarity scoring (e.g., Jaccard on tokens, Levenshtein on remaining differences).
3. **Category/synonym match**: fall back to a small curated synonym/category table (e.g., "milk" matches any dairy-milk category product; "cookies" matches the cookies category) for cases where text differs more than string similarity alone can bridge, and for image-classification results that only produce a category rather than a specific product.
4. **User confirmation**: if the top match's confidence score is below a defined threshold, or multiple shopping list items score similarly, present the candidate(s) to the user to confirm or pick, rather than auto-matching.

## Consequences

- Matching logic and the synonym/category table become an app-owned asset that needs curation and iteration over time, distinct from the AI models in ADR 0003.
- Layering keeps the common, unambiguous cases (barcode → linked catalog item) fast and silent, while pushing genuinely ambiguous cases to the user instead of guessing — reducing the risk of confusing mismatches.
- The normalized text match and category/synonym stages are deterministic and debuggable (versus an opaque ML similarity score), which matters for a small team that needs to tune matching behavior based on real user reports.
- Category/synonym table maintenance is manual initially; if mismatch rates prove too high in practice, a follow-up ADR may propose an on-device embedding-similarity model (using the TFLite runtime from ADR 0003) to replace or augment stage 3.
- Confidence thresholds will need real-world tuning; this ADR does not fix exact threshold values, only the staged approach.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Exact string match only** | Simple, fully predictable | Too brittle — fails on nearly any real-world variation in wording ("milk" vs "2% milk") |
| **Pure ML embedding similarity (single stage)** | Potentially higher recall across varied phrasing without hand-curated rules | Opaque scoring makes it hard to debug/tune mismatches; requires training/maintaining an embedding model before any matching works at all, with no simple deterministic fallback |
| **Server-side matching** | Could leverage a larger, centrally-updated product/synonym database | Violates the offline-in-store requirement; not viable given expected spotty in-store connectivity |
| **Always require manual confirmation** | Eliminates wrong-match risk entirely | Poor UX — defeats much of the purpose of automatic scanning if every match needs a manual tap |
