# ADR 0013: Nutrition Label Reading & Goal Matching

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Each user, and each member of their family/household, has personal nutrition goals — target constraints on specific nutrients (e.g., calories, protein, sugar, sodium, fat), each expressed as a minimum, a maximum, or a range. When a product is identified in-store (per ADR 0002), the app should be able to tell the user whether that product fits each household member's goals, by reading and processing the product's printed Nutrition Facts panel.

This is a distinct capture/data problem from the brand-label recognition in ADR 0002: the Nutrition Facts panel is a small-print, semi-standardized grid (serving size, calories, a list of nutrient rows each with an amount and often a % Daily Value), different in layout and content from the brand/product-name text ADR 0002's OCR fallback targets. It must also work fully offline, consistent with every other in-store capability decided so far.

## Decision

- **Model nutrition data as an attribute of the product**, attached to the same product-identity record established via barcode/OCR/classification (ADR 0002, ADR 0012), rather than re-derived from a label scan every time the product is encountered.
- **Primary source — shared/cached data, not per-scan OCR**: bootstrap and maintain nutrition data (serving size plus per-serving nutrient amounts) keyed by product identity, sourced from open nutrition datasets (e.g., Open Food Facts, USDA FoodData Central) where licensing permits, following the same bootstrap-and-crowdsource pattern established for the barcode database in ADR 0012. Sync a relevant subset to the device for offline use (ADR 0005). Unlike the barcode RCN case (ADR 0012) or pricing (ADR 0011), nutrition facts are an objective, non-location-specific property of a manufactured product, so entries are shared globally with no store- or user-scoping needed.
- **OCR fallback for unknown products**: when an identified product has no nutrition data in the local/cloud catalog, prompt the user for a secondary scan targeted at the Nutrition Facts panel specifically (the same "identify product, then optionally capture more detail" pattern used for pricing in ADR 0008), and parse it with a **structured template parser** — detecting the panel's standard header/serving-size/calories/nutrient-row grid — rather than generic free-text OCR matching, since the panel's layout is far more regular than a brand label. Offer to contribute successfully parsed (and any user-corrected) values back to the shared dataset, subject to the same abuse/error mitigation as ADR 0011/0012 (e.g., multi-contributor corroboration before a correction is trusted), with an appropriately higher bar than pricing given that wrong nutrition data is a more consequential error for someone with a dietary restriction.
- **Per-member goal profiles**: each household member has their own nutrition goal profile — a set of per-nutrient constraints (minimum, maximum, or range), scoped **per serving** (e.g., "no more than 500mg sodium per serving"), not a cumulative daily budget. Tracking actual daily/cumulative consumption against a daily target is explicitly **out of scope** for this ADR; it is a materially larger feature (meal logging, consumption tracking) that would need its own future decision if pursued. Goal profiles are stored as household-private data (ADR 0006/0007) and synced offline (ADR 0005).
- **Matching/evaluation**: when a product's nutrition data is available (cached or freshly captured), evaluate it independently against **every household member's** goal profile — not just the person doing the scanning, since a shopping trip is typically for the whole household — and present a concise, non-blocking result per member (e.g., "OK for Alex", "exceeds sodium max for Jamie") in the same scan-result UI used for coupon and price surfacing (ADR 0008/0009), rather than a separate screen.

## Consequences

- Reuses the product-identity, offline-sync, and shared-database patterns already established (ADR 0002, 0005, 0011, 0012), so this ADR is primarily a data-model and UX decision layered on existing infrastructure rather than new plumbing.
- The Nutrition Facts panel parser is a genuinely new component — a structured-grid parser distinct from both the brand-label OCR in ADR 0002 and the free-text matching in ADR 0004 — and needs its own testing against the range of real-world panel layouts and print sizes.
- Sharing nutrition data globally (rather than scoping it like store-local barcodes or anonymizing it like pricing) is reasonable since it's an objective product property, and avoids every user having to OCR the same product's panel independently — but the crowdsourcing/correction pipeline needs a higher trust bar than pricing or barcode corrections, since an incorrect nutrient value is a more consequential error for a user managing a health condition or dietary restriction.
- Scoping goal matching to a single serving (not cumulative daily tracking) keeps this decision contained and buildable, but limits its accuracy for goals that are inherently about a daily total (e.g., "sodium ≤ 2300mg per day") — a single serving being under a per-serving threshold doesn't guarantee the day's total will be; this is an accepted, explicit boundary of this ADR rather than an oversight, and is a natural candidate for a future ADR if daily/cumulative tracking is pursued.
- Evaluating against every household member's goals (not just the shopper's own) increases the matching and UI surface area, but reflects that most shopping is done on behalf of a family, not a single individual.
- Presenting results as informational per-member status (rather than a blocking warning) is consistent with the non-blocking pattern already chosen for coupon near-misses (ADR 0009), but the stakes here can be higher (health/dietary relevance), so the UI should make per-member results clearly attributable and hard to misread as applying to the wrong person.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **OCR the Nutrition Facts panel on every scan instead of caching product-level data** | Simpler mental model; no shared-database dependency | Slower and more error-prone as the primary path when a cached, previously-verified value is available — the same reasoning that put barcode lookup ahead of OCR in ADR 0002 |
| **Track cumulative daily nutrient consumption against a daily target** | More accurate answer to "does this fit my diet today" | A substantially larger feature (requires logging what's actually eaten, not just what's purchased); not implied by "matching a product against goals" alone — deferred as a possible future ADR |
| **One shared nutrition goal per household instead of per-member profiles** | Simpler data model and UI | Directly contradicts the stated requirement that each family member has their own goals |
| **Keep nutrition data private per household rather than shared globally** | Avoids any shared-data trust/quality concerns | Nutrition facts are printed, objective data about a specific product, not user- or household-specific; keeping it private would force every household to independently OCR products already resolved by others, with no benefit |
