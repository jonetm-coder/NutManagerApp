# ADR 0007: Cloud-Mobile Sync/API Protocol

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

With Firebase/Firestore proposed as the cloud backend (ADR 0006) and an offline-first local store with an outbox queue on the client (ADR 0005), we need a defined pattern for how the mobile client actually reads/writes cloud data and reconciles it with the local store, rather than treating "use the Firestore SDK" as self-explanatory. This includes deciding where direct client-to-database access is appropriate versus where a server-side API layer should mediate.

## Decision

- Use **Firestore's native offline persistence and real-time snapshot listeners** as the primary sync mechanism for straightforward CRUD data: shopping lists, list items, recipes, and household membership. The client's local database (ADR 0005) treats Firestore's local cache as its sync source, with the app-level outbox queue used specifically for the additional offline scan/match events that need app-specific conflict handling beyond what the Firestore SDK provides automatically.
- Wrap all Firestore access behind a **repository layer** in the app code (not raw Firestore calls scattered through the UI), so the backend could be swapped later (per ADR 0006's noted migration risk) without rewriting business logic or UI code.
- Use **Cloud Functions as a server-side API layer** for operations that need server-side logic, validation, or aggregation rather than direct client reads/writes — e.g., computing nutrition rollups, generating recipe recommendations, or any operation that should not trust client-side computation. The client calls these via callable Cloud Functions rather than writing derived data directly into Firestore.
- Enforce data access boundaries (a user only reads/writes their own household's data) via **Firestore Security Rules**, not solely through client-side logic.

## Consequences

- Most day-to-day sync (shopping lists, recipes) is handled by the Firestore SDK with minimal custom networking code, reducing engineering effort relative to a hand-rolled REST/GraphQL sync layer.
- The repository-layer abstraction adds a small amount of indirection now, in exchange for reducing the cost of a future backend migration — consistent with the risk flagged in ADR 0006.
- Splitting "plain data sync" (direct Firestore) from "server-side processing" (Cloud Functions) creates two access patterns to maintain, but keeps trust boundaries clear: computed/aggregated data isn't something a client can simply fabricate by writing to Firestore directly.
- Security Rules become a critical, testable artifact (household data isolation) and must be covered by tests, since they are the actual enforcement point for multi-user/household access control.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Custom REST API in front of the database** | Full control over request/response shape; backend-agnostic from day one | Must build offline caching, retry, and real-time sync largely from scratch — duplicates what Firestore already provides, for no clear benefit at this stage |
| **GraphQL API** | Flexible client-driven queries, good DX | Offline-first tooling/support for GraphQL is less mature than Firestore's built-in offline persistence; added complexity not justified given Firestore is already the backend |
| **gRPC** | Efficient, strongly-typed | Poor fit for a mobile-plus-intermittent-connectivity use case; ecosystem/tooling is oriented toward service-to-service communication, not offline-capable mobile clients |
| **All logic in Cloud Functions (no direct client Firestore access)** | Single, uniform API surface; easiest to fully control/validate | Forfeits Firestore's built-in offline persistence and real-time listeners for the common CRUD case, reintroducing the sync problem ADR 0005/0006 were meant to solve |
