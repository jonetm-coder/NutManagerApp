# ADR 0018: Health & Fitness Tracker Integration

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

The app will initially support only hand-entered values for biometric tracking (weight, blood pressure, blood sugar, etc., per ADR 0014). Integrating with health/fitness trackers (Apple Watch, smart scales, blood pressure cuffs, continuous glucose monitors, etc.) for automatic updates is an explicit long-term goal, not a near-term deliverable. The data model and integration pattern should anticipate this now, so that adding real tracker integrations later doesn't force a breaking rework of how measurements are stored and consumed.

## Decision

- Model every biometric/health measurement (per ADR 0014's biometric goal entities) as a **source-tagged record**: value, unit, timestamp, metric type, and a **source** field (e.g., `manual`, or a specific integration identifier) — never assume manual entry is the only shape data will take, even though it's the only source implemented initially.
- Build the **manual-entry path first**, as the universal baseline that works for every metric on every platform without any partner integration, matching the explicit near-term requirement.
- When device/wearable integration is eventually pursued, prefer integrating through **platform-level health data aggregators** — Apple HealthKit on iOS, Google Health Connect on Android — rather than building bespoke per-vendor integrations (e.g., a direct Fitbit or Garmin API integration). These aggregators already collect data from many underlying devices and apps a user may have (a smartwatch, a smart scale, a BP cuff, a glucose meter), so integrating once with the platform aggregator yields much broader device coverage than integrating with each vendor individually.
- Since HealthKit/Health Connect run on-device with the phone's own permission model, the client reads from them (with explicit user consent) and uploads resulting measurements to the cloud using the **same measurement record shape** as manual entries, just with the source field set to the aggregator — so downstream logic (goal matching in ADR 0014, history/reconciliation in ADR 0019) never needs to special-case where a value came from.
- Explicitly **defer building the actual HealthKit/Health Connect integration** as near-term work; this ADR's purpose is to fix the data model and integration pattern now, not to schedule the integration itself.

## Consequences

- Source-tagging every measurement from day one — even when `manual` is the only value that exists yet — avoids a breaking data migration when tracker integration is eventually added.
- Choosing platform aggregators over per-vendor integrations meaningfully reduces future integration surface area, but bounds our coverage to what those platforms support; a device with no HealthKit/Health Connect presence of its own would still require a bespoke integration if ever pursued.
- iOS (HealthKit) and Android (Health Connect) remain two distinct platform APIs with different permission and data models, so "integrate with the platform aggregator" is still two separate platform-specific efforts to eventually build — an inherent consequence of the cross-platform goal (ADR 0001), not something this decision avoids.
- Because the actual integration build-out is deferred, there is some risk that real-world implementation surfaces requirements this ADR didn't anticipate (e.g., per-metric unit/precision quirks); the data model here should be treated as a strong starting point, not an unchangeable contract.
- Multiple sources reporting the same metric (e.g., a manual weight entry and a synced smart-scale reading) raises a reconciliation question, addressed in ADR 0019.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Bespoke integration per wearable/device vendor** (direct Fitbit, Garmin, Withings APIs, etc.) | Could expose deeper per-device features than an aggregator surfaces | Large, ongoing per-vendor integration and maintenance burden; worse overall device coverage than integrating once with a platform aggregator that already covers many devices |
| **Design the manual-entry model without source tagging; add it later if integration is built** | Less upfront modeling work now | Creates a breaking data migration later, and risks manual and synced entries being modeled inconsistently since they weren't designed together |
| **Don't consider tracker integration at all until it's actually being built** | Simplest near-term scope | Risks a costly rework of the tracking/history data model at that point — exactly the outcome this ADR is meant to avoid by planning ahead |
