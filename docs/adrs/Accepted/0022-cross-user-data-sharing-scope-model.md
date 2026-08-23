# ADR 0022: Cross-User Data Sharing — Scope & Governance Model

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Several existing ADRs already establish specific instances of cross-user (crowdsourced/shared) data: pricing observations, shared globally but only meaningful/comparable within a specific store's context (ADR 0011); and barcode-to-product mappings, shared globally for GS1-assigned ranges but scoped per-store for Restricted Circulation Number ranges (ADR 0012). Recipes (ADR 0023) are the next shared-data category, and unlike pricing or store-scoped barcodes, a recipe's validity doesn't depend on the contributing user's location at all — it's equally usable by any household anywhere. As more shared-data categories are added, deciding scope, attribution, and abuse-mitigation independently for each one risks inconsistent user-facing behavior and duplicated design effort. This ADR establishes a shared taxonomy and a governance checklist that every cross-user data type — existing or future — should be classified against.

## Decision

Classify every piece of cross-user data into exactly one of three **sharing scopes**:

1. **Household-private** — never shared with other users. Shopping lists, coupons, and nutrition plans/biometric data (ADR 0006/0007, ADR 0020) fall here.
2. **Geo/store-scoped shared** — visible to other users only within the specific locality/store the data pertains to, because its validity is tied to a physical place and would be actively misleading if applied elsewhere. Store-specific pricing (ADR 0011) and Restricted Circulation Number barcode mappings (ADR 0012) fall here.
3. **Global shared** — visible to all users regardless of location, for data whose validity doesn't depend on where the contributor is. Globally-assigned barcode-to-product mappings and generic nutrition facts (ADR 0012, ADR 0013) fall here, as will recipes (ADR 0023).

For every shared data type (geo-scoped or global), require an explicit decision on each of the following, recorded in that data type's own ADR:

- **Scope classification** (one of the three above), and the reasoning for it.
- **Attribution model**: anonymous/opaque contributor (as used for pricing, ADR 0011, and barcode corrections, ADR 0012) versus named/attributed contributor (as recipes will want, ADR 0023).
- **Contribution consent**: whether contributing is opt-in, opt-out-of-default-on, or mandatory, and what a user retains access to if they opt out.
- **Abuse/quality mitigation**: how erroneous or bad-faith contributions are detected or limited (e.g., outlier detection, multi-contributor corroboration, moderation/reporting).

## Consequences

- Gives every future shared-data ADR a consistent checklist to work through, rather than re-deriving scope/attribution/abuse-mitigation policy from scratch each time — reducing the risk of inconsistent sharing behavior across features that users would find confusing (e.g., one feature anonymizing contributors while a near-identical one doesn't, for no principled reason).
- Retroactively, ADR 0011 and ADR 0012 already fit cleanly into this taxonomy (geo/store-scoped) — this ADR codifies the pattern they already established rather than changing them.
- This ADR is a governance/consistency decision, not a capability on its own; its effect is realized through the per-data-type ADRs (0011, 0012, 0023, and future ones) that reference it. It should be updated if a genuinely new sharing scope is needed (e.g., a "shared within a household group but not fully public" tier), rather than forcing every future case into one of the three scopes defined today.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Let each data-sharing ADR define its own scope/attribution/abuse-mitigation model independently** | More flexibility per case | Risks inconsistent user-facing sharing/privacy behavior across features, and duplicates the same design questions repeatedly |
| **Use a single sharing model for everything (e.g., always anonymous, always global)** | Simplest possible policy | Incompatible with recipes wanting attribution (ADR 0023), and incompatible with the geo-scoping pricing/barcode data needs to avoid being misleading outside its local context |
