# ADR 0015: Cloud/Local Processing Split for Nutrition Planning & Tracking

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

The in-store shopping subsystem (ADR 0005) must assume no or spotty connectivity and is therefore local-first, with the phone holding the source of truth and syncing opportunistically. The nutrition planning and tracking subsystem — creating plans (ADR 0014), building/importing recipes (ADR 0016), and logging biometric measurements over time (ADR 0019) — can instead assume the user **generally has internet connectivity** while doing this work. This changes the natural architecture tradeoff and warrants its own decision rather than inheriting ADR 0005's model by default. Some overlap does exist, though: the in-store goal-matching check (ADR 0013) still needs offline access to whatever goals are currently active.

## Decision

- Treat the **cloud as the source of truth** for nutrition plans, goals, recipes, and tracked history — the opposite default from ADR 0005's local-first model for shopping. The mobile client is primarily a thin, connectivity-assuming client for this subsystem: creating/editing plans and recipes, and reviewing history, are online operations.
- Perform recipe nutrient computation (ingredient resolution, unit scaling, cooking-method adjustment per ADR 0017) as a **server-side (Cloud Function) operation**, not on-device: it depends on centrally-maintained reference data (the generic-ingredient database in ADR 0016, the retention-factor tables in ADR 0017), doesn't need to run in real time while offline in a store, and centralizing it avoids re-implementing the same computation on every client platform.
- Maintain a **narrow, read-only local snapshot** of each household member's *currently active* goals specifically to support the offline in-store matching use case (ADR 0013). This is a deliberate, limited exception to the "cloud is source of truth" rule — not a general offline-editing capability for plans, recipes, or history.
- Manual biometric/intake entries made without connectivity (a plausible occasional gap even though connectivity is generally assumed) are queued locally using the same outbox pattern as ADR 0005, as a fallback for that gap — not the primary design assumption for this subsystem.

## Consequences

- Meaningfully simplifies the planning/tracking subsystem relative to the shopping subsystem: no need for a full local replica, multi-device conflict resolution, or offline-first UI patterns for plan editing, recipe management, or history browsing.
- The app now contains two different architectural postures — cloud-first for planning/tracking, local-first for in-store scanning — which must be clearly documented (this ADR, and cross-referenced from ADR 0005) so contributors don't assume one pattern applies everywhere in the codebase.
- Server-side recipe computation means a recipe created or edited while offline has no computed nutrition until connectivity returns; accepted as reasonable given the "generally connected while planning" assumption.
- The local goal snapshot for in-store matching must be kept explicitly scoped to that one read-only use case, to prevent scope creep back toward a full local-first model for the planning subsystem that this ADR is deliberately avoiding.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Fully local-first for planning/tracking too, mirroring ADR 0005** | One consistent architectural pattern across the whole app | Unnecessary complexity (full local replicas, conflict resolution) for a subsystem that doesn't need to tolerate lack of connectivity |
| **Compute recipe/cooking-method nutrients on-device** | Keeps computation available offline immediately after editing; no server round-trip | Duplicates computation logic across platforms and requires shipping the full nutrient/retention-factor reference dataset to every device instead of centralizing it |
| **No local snapshot at all; require connectivity even for in-store goal matching** | Simplest possible design | Breaks the offline in-store requirement already established in ADR 0005/ADR 0013 |
