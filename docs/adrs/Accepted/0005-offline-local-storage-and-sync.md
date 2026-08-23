# ADR 0005: Offline-First Local Storage & Sync

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

The app's core in-store use case — scanning and matching items to a shopping list — must work with no or spotty connectivity. Before entering the store, the app is expected to have connectivity to download the current shopping list and relevant product/nutrition data from the cloud (ADR 0006). While in the store, all reads (shopping list, cached catalog lookups) and writes (marking items found/purchased, new scan results) must happen against a local store, with changes queued and reconciled with the cloud once connectivity returns.

The device also cannot reasonably hold the entire product/nutrition catalog offline — it must cache a relevant working subset.

## Decision

- Use an embedded local database (e.g., SQLite via the `drift` package, or an equivalent Flutter-compatible embedded DB) on-device to store: the active shopping list(s), a cached subset of the product catalog (items relevant to the household's history/current list), and an outbox queue of pending changes (items checked off, new scan-to-product matches, ad hoc list additions) made while offline.
- Before a shopping trip (whenever connectivity is available), proactively sync down: the current shopping list(s) and the catalog subset needed to resolve it — items previously purchased by the household, items on the current list, and their known category/synonym data.
- While offline, all reads and writes go through the local database only; the app must never block a user action on network availability.
- When connectivity returns, drain the outbox queue against the cloud backend, applying a defined conflict-resolution rule (last-write-wins per field, using timestamps) for cases where the same list/item changed on another device in the meantime.

## Consequences

- The app has a genuine offline mode rather than a "degraded" one — this is a hard requirement given expected in-store connectivity, so local storage and the outbox queue are core architecture, not an add-on.
- Conflict resolution is simplified (last-write-wins) rather than field-level or CRDT-based merging, which is easier to build and reason about but can silently drop a concurrent edit from another family member's device in rare cases.
- Catalog subset selection (what to pre-download before a trip) needs its own heuristic and will require tuning; too narrow a subset increases fallback-to-OCR/classification rate in-store, too broad increases sync time/storage use.
- Local DB schema and the outbox queue format become a long-lived contract with whatever cloud backend is chosen in ADR 0006, so that ADR should be evaluated for how well it supports this sync model (e.g., built-in offline persistence vs. one we build ourselves).

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **No local persistence; rely on backend's offline cache (if any)** | Less code to write/maintain in the app | Ties the app's offline behavior entirely to the chosen backend SDK's caching guarantees, which may not exist yet (ADR 0006 not decided) or may not support the outbox/queue semantics we need |
| **Full local replica of the entire product/nutrition catalog** | Never a cache miss in-store | Catalog is expected to be large (national product/nutrition data); not practical to fully replicate to a phone; unnecessary given most trips only touch a small, predictable subset |
| **CRDT-based sync (e.g., Automerge/Yjs-style)** | Robust, automatic conflict resolution without losing concurrent edits | Meaningfully higher implementation complexity than last-write-wins; not justified for the prototype stage, but worth revisiting if last-write-wins proves too lossy for family/multi-device use |
