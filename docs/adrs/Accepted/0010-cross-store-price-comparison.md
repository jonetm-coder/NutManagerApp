# ADR 0010: Cross-Store Price Comparison by Locality

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Users want to know whether a product is cheaper at a different nearby store, using price observations captured per ADR 0008 and accumulated over time in the cloud per ADR 0011. This requires deciding how to group price observations by store/locality and how the comparison is presented, given that a single household's own scans will typically only cover one or two stores it regularly shops at, so meaningful comparison depends on the broader (crowdsourced) price history from ADR 0011.

## Decision

- Key every price observation by **(product identity, specific store, timestamp)**, where "specific store" is an actual store location (chain + address/geolocation), not just a city or ZIP code — prices are known to vary between locations of the same chain, so coarser grouping would produce misleading comparisons.
- Identify the store for a given shopping trip via the user's current location (with permission) or an explicitly selected/saved store profile, established once per trip rather than re-derived per scan.
- The price comparison view for a given product shows prices from stores within a **user-configurable radius** of the user's location (or from the user's explicitly saved/favorite stores), sourced from the cloud price history (ADR 0011), not limited to the current household's own scans.
- Since the comparison view depends on cloud data and in-store connectivity may be unavailable (ADR 0005), pre-sync price history for the user's frequently-visited/favorite stores whenever connectivity is available, and clearly label comparison data with its last-synced timestamp when shown offline, rather than blocking the feature entirely without connectivity.

## Consequences

- Store-level (not just city-level) grouping gives more accurate comparisons but requires reliable store identification per trip (geolocation permission, or user diligence in selecting a store profile) and a maintained store directory (chain + specific locations) as reference data.
- The feature's usefulness depends heavily on the crowdsourced pricing data pipeline in ADR 0011; a lightly-used app in a given area will show sparse or stale comparisons for other stores, with only the household's own store(s) reliably populated.
- Offline degradation (showing last-synced data with a visible timestamp) trades real-time accuracy for availability in the primary in-store use case, which is an intentional tradeoff given the offline-first requirement — the comparison feature is expected to be used at home while planning, more than live in-aisle.
- A configurable radius adds a small UI/settings surface but avoids hardcoding an assumption about how far users are willing to travel for savings.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Compare only within the household's own scan history** | No dependency on crowdsourced data quality/coverage | Provides little to no genuine cross-store comparison value, since most households only regularly shop 1-2 stores |
| **Group by store chain only (ignore specific location)** | Simpler data model, no per-location store directory needed | Hides real price variation between locations of the same chain; can produce misleading "this store is cheaper" conclusions |
| **Unrestricted global comparison (no locality grouping)** | Simplest possible query | Surfaces prices from stores far outside any store the user could realistically shop at, reducing the feature's practical usefulness |
