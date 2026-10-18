# ADR 0025: Nutrition Data Trust & Validation Model

- **Status:** Accepted
- **Date:** 2026-10-18
- **Author(s):** jonetm@gmail.com

## Context

ADR 0013 established that nutrition data is sourced from open datasets (Open Food Facts, USDA FoodData Central) and shared globally, with crowdsourced corrections "subject to the same abuse/error mitigation as ADR 0011/0012 (e.g., multi-contributor corroboration before a correction is trusted), with an appropriately higher bar than pricing." NUTL-4 restates the same intent — a higher validation/corroboration bar for nutrition than for pricing or barcode corrections — but neither ADR 0013 nor NUTL-4 specifies a concrete mechanism.

That gap matters more for nutrition data than for almost anything else this app handles. A wrong barcode-to-product mapping is an inconvenience — the wrong item shows up, the user corrects it. Wrong nutrition data is a different kind of error: NUTL-1 uses it to tell a household member with a dietary restriction or health condition (diabetes, hypertension, a sodium or allergen restriction) whether a product fits their goals. Multi-contributor corroboration — several anonymous or pseudonymous contributors independently submitting the same value, the pattern already established for pricing (ADR 0011) and barcode corrections (ADR 0012/BC-3) — is a weaker signal than NUTL-4 itself says this data needs: agreement among strangers isn't the same as verification.

Products also aren't static. Manufacturers reformulate recipes, change serving sizes, or adjust ingredients, so even correctly-captured nutrition data can go stale. A trust model that treats validation as a permanent, one-time stamp would eventually present confidently-wrong data as if it were still verified.

This ADR defines an explicit trust model for nutrition data: which sources are trusted and why, how non-authoritative data earns trust, how that trust is recorded, and how it expires.

## Decision

**Trust tiers**, highest to lowest:

1. **Government-sourced (USDA FoodData Central).** Trusted automatically — no human validation step required. This is the first source checked for any product's nutrition data: a branded-food UPC match where available, a generic-food match as fallback for unbranded ingredients/recipe components. If FoodData Central has the product, that value is canonical and takes precedence over any conflicting household-validated or maintainer-verified entry for the same product — government lab/manufacturer-submitted data outranks a human spot-check.
2. **Maintainer-verified.** A NutManager maintainer has explicitly confirmed a product's nutrition data (e.g., checked it against the actual packaging) and promoted it to global trust. Once verified, shown to every household with the same confidence as USDA data.
3. **Household-validated.** A member of a specific household has confirmed the data matches their physical product's label. Trusted only within that household — other households see the same underlying values, but flagged as unverified for them, not inherited as trusted.
4. **Unverified.** Data from an open/crowdsourced source (Open Food Facts' nutrition fields, a freshly-OCR'd panel nobody has confirmed yet) with no human validation at all. Still shown and still usable — better than nothing — but NUTL-1's per-member goal-fit indicator must visibly distinguish an unverified-data verdict from a trusted one (e.g., "OK for Alex (unverified)" rather than presenting it with the same confidence as a trusted result). Never silently presented as equivalent to a trusted value.

**Lookup order:** always check USDA FoodData Central first. If present, use it, full stop. If absent, fall back to whatever's cached, preferring maintainer-verified, then household-validated-for-this-household, then unverified — always surfaced with its actual trust tier, never silently upgraded.

**Validation process:**

- **Household validation** is triggered when a household member reviews an unverified entry (from the goal-fit screen, or a dedicated "verify this product" action) and confirms it matches their product's panel — ideally by comparing against a fresh OCR capture via ADR 0013's structured panel parser, so the confirmation is tied to an actual observation rather than a blind "looks right" tap. This records the household, the member, a timestamp, and a snapshot of the exact values validated (see Recording, below).
- **Maintainer verification** is a manual, out-of-band action (e.g., a maintainer-only NutCache admin tool or Cloud Function) where a maintainer confirms a product's data against an authoritative source — ideally the actual packaging — and promotes it to global trust. A maintainer verification can be informed by an existing household validation (reviewing and promoting a household's own work, reducing duplicate effort) but is always a distinct, explicit action; a household validation never auto-promotes itself to global trust.

**Recording:** trust status attaches to a specific **snapshot of the nutrient values**, not to the product record in general. If the underlying values are later edited or re-captured, the prior trust status does not carry over — the new values start unverified again and need their own validation. Each nutrition-data record stores:
- `source`: `usda` / `maintainer-verified` / `household-validated` / `unverified`
- `validatedBy`: a household ID (household-tier) or maintainer identity (maintainer-tier); absent for `usda`/`unverified`
- `validatedAt`: timestamp
- `revalidateBy`: computed expiry (see below)

Household-tier validation records are household-private data, consistent with ADR 0006/0007's existing household-scoping model. Maintainer-tier and USDA-tier records are global/shared, consistent with ADR 0013's existing stance that nutrition facts are shared globally as an objective product property.

**Re-validation period:** human-granted trust (household or maintainer tier) expires **12 months** after `validatedAt` by default, reverting the entry to `unverified` — not deleted, the last-known values stay visible, just downgraded until re-validated. USDA-sourced data doesn't expire this way; it's re-synced from FoodData Central on NutCache's regular sync cadence (the same "sync a relevant subset" pattern ADR 0012 already established for the barcode database) rather than a point-in-time human check going stale. The 12-month figure is a judgment call, not derived from a formal study of reformulation frequency — documented explicitly here, the same way `MatchingService`'s confidence thresholds are documented in the mobile app, so it's a visible, revisitable parameter rather than an unstated constant. Shorter periods increase validation burden on households and maintainers; longer periods increase the risk of presenting stale data as trusted.

## Consequences

- Products FoodData Central already covers (likely most well-known branded products) need zero manual trust-building effort — the trust model's real overhead concentrates on the long tail USDA doesn't have.
- Household-tier trust being household-scoped, not shared, means the same validation work can be repeated independently by many households for a product USDA doesn't cover. This is a deliberate trade-off favoring safety (no crowd-trust gaming via sock-puppet corroboration) over efficiency; maintainer verification is the intended path to eliminate that duplication once a product proves common enough to be worth a maintainer's time.
- Tying trust to a specific value snapshot, not the product record generally, adds real data-model complexity (versioned snapshots, not overwrite-in-place) — but without it, a "trusted" badge could silently keep applying after the underlying values changed, which given the health stakes here is a genuine integrity gap, not a nice-to-have.
- A fixed 12-month re-validation horizon adds ongoing maintenance load (expired entries need re-review, whether a household notices a downgraded badge or a maintainer proactively re-checks a high-traffic product), but is the direct answer to products changing their ingredients over time.
- This is a genuinely different trust mechanism than ADR 0012 uses for barcode corrections (multi-contributor corroboration), by design: NUTL-4 already calls for a higher bar for nutrition than barcodes/pricing, and this ADR's position is that several anonymous contributors agreeing is not that higher bar — a specific, accountable action (a household's own observation, binding only for them; or a maintainer's explicit, globally-binding check) is.
- This refines, rather than fully supersedes, ADR 0013: ADR 0013's product-identity modeling, structured panel parser, per-member goal matching, and global-sharing stance for nutrition data all remain in force unchanged. Only its crowdsourcing-trust sentence (generic "multi-contributor corroboration... with an appropriately higher bar than pricing," with no specified mechanism) is superseded by this ADR's concrete tiered model. A cross-reference note has been added to ADR 0013 pointing here.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| Multi-contributor corroboration (ADR 0011/0012's existing pattern, applied unchanged to nutrition) | Reuses existing infrastructure/pattern; no new maintainer workflow needed | Several anonymous/pseudonymous contributors agreeing is a weaker signal than a specific, accountable validation action — NUTL-4 already says nutrition needs a *higher* bar than this pattern provides, not the same one |
| Trust all non-USDA data equally once contributed, no tiered household/maintainer distinction | Simplest possible model | Fails to distinguish one household's unverified assumption from a maintainer's confirmed check — exactly the ambiguity this decision exists to resolve |
| No re-validation — trust is permanent once granted | Less ongoing maintenance burden | Ignores that products get reformulated; a permanently-trusted stamp on stale data is arguably worse than no trust badge at all, since it's actively misleading rather than honestly uncertain |
| Household validations aggregate toward automatic global trust after N independent households validate the same values, no maintainer needed | Could reduce duplicate validation work across households without consuming maintainer time | Reintroduces a crowd-corroboration mechanic for the *global* tier, which is exactly what this ADR (and NUTL-4) argues is insufficient for health-relevant data; deferred as a possible future refinement if maintainer bandwidth proves to be a real bottleneck, not adopted now |
