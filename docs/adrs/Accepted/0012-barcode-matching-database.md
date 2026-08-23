# ADR 0012: Barcode Matching Database

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

ADR 0002 treats barcode decoding as the fast, reliable primary path for product identification, and ADR 0003 handles the decoding itself. What decoding does *not* solve is: given a decoded barcode value, reliably determining *what product it identifies*. In practice, barcodes are far less standardized than they first appear:

- **GS1 does not guarantee global uniqueness in practice.** Company prefixes are assigned centrally, but enforcement, database completeness, and correction of errors are inconsistent; duplicate or mis-registered codes exist in the wild.
- **Restricted Circulation Numbers (RCNs)** — barcodes in certain prefix ranges (e.g., UPC-A numbers starting with 2, or EAN-13 numbers starting with 02/04/20-29) — are explicitly reserved for **local/in-store use only** and are *not* globally unique. The same numeric code can mean a completely different product at a different store or chain.
- **Variable-weight/price-embedded barcodes**: many of those same RCN-range barcodes (common on meat, deli, produce, and bakery items weighed at the store) encode the item's *weight or price* directly in the barcode digits, not a stable product identifier. Two packages of the same product will have different barcode values, and naively treating the full code as a lookup key produces false non-matches or, worse, collisions with an unrelated product's code.
- **No single authoritative, complete, free public database** of barcode-to-product mappings exists; available sources are a mix of paid commercial APIs (coverage/accuracy varies, ongoing cost, requires connectivity) and open/crowdsourced datasets (variable quality and coverage, but community-correctable).

This directly affects the reliability of the "primary path" in ADR 0002 and needs its own decision, since getting it wrong produces silently incorrect product matches rather than an obvious failure.

## Decision

Build and maintain our **own barcode matching database**, layered as follows:

1. **Barcode parsing/classification stage** (runs before any lookup): classify a decoded barcode by its symbology and numeric range to detect RCN/variable-weight patterns per known GS1 rules (e.g., prefix + item-reference digits vs. embedded weight/price digits + check digit). For recognized variable-weight formats, extract only the stable item-reference portion as the lookup key, discarding the embedded weight/price digits.
2. **Two-tier lookup key scoping**:
   - Barcodes in **globally-assigned GS1 ranges** are looked up/stored as **global entries**, shared across all users (same model as the shared pricing data in ADR 0011: no personal attribution, opt-in/opt-out contribution).
   - Barcodes in **RCN/local-use ranges** are looked up/stored as **store-scoped entries** (keyed by store, per ADR 0010's store-identity model), never treated as a global match, since the same code legitimately means different things at different stores.
3. **Bootstrapping from open data**: seed the initial database from existing open/crowdsourced barcode datasets (e.g., Open Food Facts and similar open product databases) where licensing permits, rather than starting from zero; do not depend on any paid commercial barcode API as a hard runtime dependency.
4. **Crowdsourced contribution and correction**: when a user resolves an unknown barcode (via OCR fallback or manual entry, per ADR 0002) or corrects a wrong match, offer to contribute that mapping back to the shared database, subject to the same lightweight validation/outlier/abuse mitigation approach established for shared pricing data in ADR 0011 (e.g., requiring corroboration from more than one independent contributor before a global mapping is trusted, especially for corrections to an existing entry).
5. **Offline availability**: sync a relevant subset of the barcode database to the device (global entries for products in the user's cached catalog/shopping list, plus store-scoped entries for the user's frequently-visited stores) as part of the pre-trip sync described in ADR 0005, so lookups work without connectivity in the common case.

## Consequences

- Correctly separating global vs. store-scoped barcode ranges avoids a known, real-world failure mode (RCN collisions) that a naive "barcode is a unique key" assumption would hit immediately with produce, deli, and many private-label items.
- Building our own database (rather than depending solely on a third-party paid API) avoids an ongoing per-lookup cost and a hard connectivity dependency, at the cost of taking on data-quality and coverage responsibility ourselves.
- Bootstrapping from open datasets reduces cold-start effort but ties initial data quality/coverage to those sources' completeness and licensing terms, which must be checked before redistribution.
- Crowdsourced correction introduces the same abuse/data-quality surface as shared pricing (ADR 0011) and needs analogous mitigation (multi-contributor corroboration, outlier/anomaly checks via Cloud Functions per ADR 0007); this is additional engineering scope beyond simple key-value storage.
- Store-scoped RCN entries add a dimension (store identity) to what would otherwise be a simple global barcode table, increasing schema and sync complexity, but this is necessary to avoid incorrect matches rather than optional.
- The barcode parsing/classification stage must be kept current with GS1 range rules and is a small but nontrivial piece of domain logic that needs its own tests and reference documentation, since it silently determines correctness of everything downstream (ADR 0004 matching, ADR 0008 pricing, ADR 0009 coupons all key off product identity established here).

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Rely solely on a third-party paid barcode lookup API** | Fast to bootstrap; offloads data maintenance | Ongoing per-call cost; coverage of regional/local/private-label products is typically poor; hard dependency on connectivity, in tension with the offline-first requirement (ADR 0005) unless heavily cached anyway (at which point we're building our own cache/database regardless) |
| **Treat every barcode as a globally unique key (no RCN/variable-weight handling)** | Simplest possible implementation | Produces wrong or missing matches for produce, deli, meat, and many private-label items — a common, not edge-case, scenario in grocery shopping |
| **Fully proprietary, manually curated database only (no crowdsourcing)** | Highest control over data quality | Far too slow to reach useful coverage of a typical store's SKU range with a small team; no mechanism to keep pace with new products |
| **No shared database at all — resolve every unknown barcode via OCR/manual entry each time, with no persistence/sharing** | No data-quality or abuse-mitigation engineering needed | Repeats the same manual-resolution cost for every user encountering the same product; wastes the crowdsourcing opportunity that ADR 0011 already establishes a pattern for |
