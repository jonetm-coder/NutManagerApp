# ADR 0011: Cloud Historical Pricing Data & Cross-User Sharing

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

The cross-store comparison feature (ADR 0010) and any price-trend tracking depend on a historical record of prices per product per store over time. A single household's own scans will only ever cover the stores that household visits, so meaningful comparison value requires **sharing price observations across users** — i.e., crowdsourcing pricing data — rather than keeping it siloed per household like shopping lists and recipes. This introduces a distinct data-modeling and privacy consideration not present in the household-private data covered by ADR 0006/0007: a price observation is tied to a place and time a specific user was shopping, which is sensitive if attributed to an identifiable person.

## Decision

- Store price observations in a **shared, cross-household collection** in the cloud backend (Firestore, per ADR 0006) — separate from household-private data (shopping lists, recipes, coupons) — keyed by product identity, store, and timestamp, matching the model established in ADR 0010.
- **Do not attach personally identifying information** to shared price records. Each submission carries only an opaque contributor token (e.g., a random per-device/session identifier) sufficient for basic abuse mitigation, not user identity or household linkage.
- Let users **opt out** of contributing their scanned prices to the shared pool; opting out does not affect their ability to view shared price history or to keep their own household's price history privately (household-private price data, if kept, is scoped like other household data per ADR 0007).
- Validate and lightly aggregate incoming price submissions via a Cloud Function (per ADR 0007) before they affect what other users see — e.g., flagging or discounting submissions that are strong outliers relative to recent observations for the same product/store, to reduce the impact of erroneous or bad-faith entries.

## Consequences

- Enables the cross-store comparison feature (ADR 0010) to have meaningful coverage beyond a single household's own shopping history, which is the entire point of collecting this data centrally.
- Keeping shared pricing data free of personal/household identifiers is a deliberate privacy tradeoff: it limits our ability to track down or penalize a specific bad-faith contributor beyond blocking their opaque token, in exchange for not building a de-facto shopping/location history tied to identifiable users.
- Outlier detection/validation in Cloud Functions adds engineering scope beyond simple writes, but is necessary since shared data quality directly affects a user-facing feature (a bad price shown as "cheaper elsewhere" erodes trust quickly).
- This is a second, structurally different data-sharing model alongside household-private data, so security rules and data-access code must clearly distinguish "shared/public pricing" from "household-private" collections to avoid accidentally leaking one into the other.
- Future integrations (e.g., a formal retailer price-feed partnership) could supplement or eventually replace crowdsourced data, but are not assumed by this decision.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Keep pricing fully private per household** | Simplest privacy story; reuses household-private data model as-is | Undermines the premise of cross-store comparison (ADR 0010), which needs data beyond what one household can generate |
| **Use a third-party pricing data provider/API instead of crowdsourcing** | Avoids building submission/validation pipeline; potentially higher initial data quality | Unlikely to have granular coverage of arbitrary local/independent stores; ongoing licensing cost; introduces a dependency on an external data vendor for a core feature |
| **Store shared price submissions with full user attribution** | Better accountability/fraud tracing per contributor | Creates an identifiable shopping/location trail per user, a meaningful privacy risk not justified by the modest accountability benefit |
