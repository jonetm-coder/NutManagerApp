# ADR 0006: Cloud Backend Platform

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Beyond the mobile client, the broader ecosystem includes cloud storage and processing for a user and their family/household: nutritional information, recipes, and shopping lists, shared across household members and devices. The backend must:

- Support multi-user/household data sharing (a shopping list or recipe belongs to a household, not just one user).
- Serve as the source of truth that the mobile client syncs against (feeding ADR 0005's local cache/outbox model).
- Be buildable and operable by a small team without heavy dedicated ops/infra work, at least at the prototype stage.
- Leave room to grow into heavier "cloud processing" (e.g., nutrition analysis, recipe recommendations) without a backend rewrite.

## Decision

Use **Firebase** (Firestore for data, Firebase Auth for identity, Cloud Functions for server-side logic, Cloud Storage for any binary assets such as label images) as the initial cloud backend platform.

Rationale:

- Firestore has first-party, mature Flutter SDK support and built-in offline persistence/real-time listeners, which pairs naturally with the offline-first client design in ADR 0005 and can reduce custom sync-engine code.
- Firebase Auth provides household/multi-user identity and access control (e.g., security rules scoping data to a household) without building auth infrastructure from scratch.
- Cloud Functions gives a place to run server-side "processing" (nutrition computation, recipe suggestions) as the ecosystem grows, without standing up separate backend infrastructure.
- Minimal ops burden fits a small team at the prototype stage; a managed, pay-as-you-go platform avoids upfront infrastructure investment before product-market fit is established.

## Consequences

- Data modeling is constrained to Firestore's document/collection model, which is a good fit for shopping lists/recipes but is less natural for complex relational queries or heavy analytical workloads (e.g., detailed nutrition trend reporting across a household over time).
- The team takes on a dependency on Google Cloud/Firebase pricing and platform decisions; migrating off Firestore later would require a data-model and sync-layer rewrite.
- Real-time listener and offline-cache behavior is largely "free" from the SDK, directly benefiting ADR 0005, but also means the client's offline behavior is partly shaped by Firestore's own caching semantics rather than being fully custom.
- As "cloud processing" needs grow (e.g., ML-driven recipe recommendations, larger nutrition datasets), some workloads may outgrow Cloud Functions/Firestore and require a supplementary service (e.g., a dedicated compute service reading from Firestore or a data warehouse export) — this is anticipated, not blocked, by this decision.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Supabase (Postgres-based)** | Relational data model better suited to complex nutrition/reporting queries; open-source, avoids vendor lock-in to Google | Offline-first mobile sync is less turnkey than Firestore's built-in offline persistence; smaller/newer ecosystem |
| **AWS (AppSync/Amplify + DynamoDB or RDS)** | Highly scalable, most configurable, fits well if already invested in AWS | Significantly more setup/ops overhead for a small team; offline sync (Amplify DataStore) is less mature/well-trodden for Flutter than Firestore |
| **Custom backend (e.g., Node/Python + Postgres) on a managed host** | Full control over data model and business logic; best long-term flexibility | Must build auth, real-time sync, and offline reconciliation support largely from scratch — substantial upfront engineering cost not justified at the prototype stage |
