# ADR 0009: Coupon Handling & Matching

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Users commonly apply coupons that reduce the price of a specific product or category, in two forms:

- **Printed coupons**: paper coupons (manufacturer or store), typically encoded with a GS1 DataBar/UPC-family barcode carrying an offer code, product restrictions, and a value.
- **Electronic coupons**: digital coupons loaded into a store's own loyalty app or a manufacturer's digital wallet, which this app generally cannot read directly since they live inside third-party apps/accounts we don't control.

Coupons carry restrictions beyond a simple product match: expiration date, minimum purchase quantity, size/variant exclusions, and sometimes a specific store or store chain. Matching a coupon to a scanned product (per ADR 0004) and its captured price (per ADR 0008) needs to account for these restrictions rather than a bare product match.

Beyond exact matching, there is a common near-miss case worth surfacing: a user has a coupon for a specific product (e.g., a particular brand/size of peanut butter), but scans a different product in the **same category** (a different brand or size of peanut butter) that the coupon does not apply to. Left unmentioned, the user may not realize a cheaper or coupon-eligible alternative exists on the same shelf.

## Decision

- **Printed coupons**: scan the coupon's barcode using the same barcode capture path as product identification (ADR 0002/0003). Parse it as a GS1 DataBar Coupon / UPC-A coupon code to extract the offer code, product family/restrictions, value, and expiration where encoded in the barcode itself.
- **Electronic coupons**: since direct integration with arbitrary store loyalty platforms is out of scope for the prototype, support **manual coupon entry** (user enters the coupon's product, value, and expiration, or scans a printed representation of it such as a flyer or emailed coupon) as the initial mechanism. Store entered coupons in the cloud backend (ADR 0006) so they sync across the household's devices. Direct store-account integration is deferred to a future ADR if pursued.
- **Matching**: extend the layered matching strategy from ADR 0004 with a coupon-matching stage: once a shopping-list item is matched to a scanned product, check any coupons on file against that product for applicability (expiration not passed, quantity threshold met by current list/cart contents, no excluded variant), and surface applicable coupons to the user rather than auto-applying silently.
- **Same-category, different-product warning**: when a scanned product does *not* match any coupon on file exactly, additionally check whether any coupon on file targets the **same category** (using the category/synonym data from ADR 0004) as the scanned product. If so, surface a non-blocking warning ("You have a coupon for [product X] in this category — this item doesn't qualify") rather than silently saying nothing. This is informational only; it never auto-substitutes or auto-applies the coupon, since the user may have a deliberate reason (allergy, brand preference, size need) for choosing the scanned item anyway.

## Consequences

- Reuses the existing barcode capture pipeline for printed coupons, keeping the new capture surface small.
- Electronic coupon support is initially manual-entry-only, which is lower-effort but places the burden of accuracy on the user; this is an accepted limitation for the prototype rather than a long-term design goal.
- Coupon restriction logic (expiration, quantity thresholds, exclusions) is additional business logic layered on top of ADR 0004's matching, increasing the complexity of the matching/confirmation UI (a match may now have an associated "coupon applies" or "coupon almost applies" state).
- Surfacing rather than auto-applying coupons avoids incorrectly claiming a discount the user doesn't actually qualify for at checkout, at the cost of an extra user confirmation step.
- Storing user-entered coupons in the shared cloud backend raises the same data-scoping question as household shopping lists — coupons are household-private data (unlike the shared pricing data in ADR 0011) and must be scoped accordingly via the security rules established in ADR 0007.
- The same-category warning depends on the same-category logic already established for product matching (ADR 0004's category/synonym table) rather than introducing a new categorization mechanism, but it does add a distinct "near miss" UI state alongside "coupon applies" — the confirmation UI now needs to distinguish match, near-miss, and no-coupon cases rather than a simple applies/doesn't-apply binary.
- Because the warning is informational and non-blocking, it carries low risk of being wrong or annoying in isolation, but if category groupings are too coarse (per ADR 0004's ongoing tuning), it could fire too often (e.g., warning on every unrelated size/flavor variant) and become noise the user learns to ignore; category granularity should be tuned with this use in mind, not just product matching.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Printed coupons only, no electronic coupon support** | Simpler scope | Misses a large and growing share of real-world coupon usage (store apps, manufacturer digital coupons) |
| **Attempt direct store loyalty/wallet API integration for electronic coupons** | Fully automatic, no manual entry | Requires per-retailer integration work and agreements; far too large in scope for the prototype; explicitly deferred rather than attempted now |
| **No restriction parsing — treat any coupon as a flat product discount** | Much simpler matching logic | Risks presenting coupons as applicable when they actually are not (wrong quantity, expired, excluded variant), misleading the user at checkout |
| **No same-category near-miss warning (only exact coupon matches surfaced)** | Simpler matching/confirmation UI with only one "applies" state | User may unknowingly buy a non-coupon product when a coupon-eligible alternative in the same category was available, missing savings the app could have surfaced |
| **Auto-suggest/auto-substitute the coupon-eligible product instead of just warning** | Could more directly drive the user toward savings | Presumes the user's brand/size/allergy preferences don't matter, which isn't a safe assumption; more intrusive than a simple informational warning |
