# NutManagerApp

See [README.md](README.md) for the human-facing project overview, naming conventions (NutManager, NutCache, Securing NUTS, and how names appear in identifiers), and development environment setup instructions.

## Project

NutManagerApp is a mobile app, part of a larger ecosystem with cloud storage/processing, that lets a user scan a product label, classify the product, and match it to a shopping list.

- **Cloud side (NutCache):** the server side of the application is called **NutCache**. It stores nutritional information, recipes, and shopping lists for a user and their household/family; also maintains historical pricing data shared/crowdsourced across users.
- **Mobile side:** downloads the shopping list ahead of a shopping trip, then must scan/categorize items and match them to the shopping list **offline**, since in-store connectivity is expected to be spotty. Also captures item pricing and coupons while shopping.
- **Platforms:** Android prototype first, iOS planned to follow; leaning toward Flutter for cross-platform client code (see ADR 0001).
- **On-device AI:** product classification/matching must run on the phone itself, not the cloud, to satisfy the offline requirement (see ADRs 0002-0004).
- **Pricing & coupons:** capturing shelf/hand-marked prices and coupons, matching coupons to products, and comparing prices across stores by locality using shared historical data (see ADRs 0008-0011).
- **Cross-user data sharing:** a general scope/governance model (private vs. geo/store-scoped vs. global sharing) covers all crowdsourced data — store-specific pricing and barcode data are geo-scoped, while recipes are shared globally since they aren't tied to a location (see ADRs 0022-0024). Recipe sharing raises copyright/liability questions that need real legal review before launch (ADR 0024).
- **Nutrition planning & tracking:** users create a nutrition plan (min/max/range targets per nutrient) and track biometric goals (weight, blood pressure, blood sugar, etc.) per household member; recipes are created/imported and their nutrient content computed from ingredients, adjusted for cooking method. Unlike in-store shopping, this subsystem assumes general connectivity and is cloud-first rather than offline-first (see ADRs 0014-0019). Health tracker integration (e.g., Apple Watch) is a long-term goal designed for now but not built yet (ADR 0018). Health data privacy/HIPAA implications are tracked separately (ADR 0020), including the planned long-term requirement to share data with a user's healthcare provider (ADR 0021).

All architectural decisions below have been accepted — see [docs/adrs/Accepted/](docs/adrs/Accepted/).

## Documentation

- [docs/adrs/](docs/adrs/) — Architectural Decision Records (ADRs). See [docs/adrs/README.md](docs/adrs/README.md) for the process.
- [docs/requirements.md](docs/requirements.md) — Functional requirements derived from the ADRs, each with a priority (Must/Should/Nice to Have) and acceptance criteria (filled in where known). Update this alongside the ADRs as decisions evolve.
- [docs/design/](docs/design/) — Design notes that don't rise to the level of an ADR (interim/temporary setups, implementation notes tied to an accepted ADR, etc.). Currently: [NutCache dev instance](docs/design/nutcache-dev-instance.md), describing the temporary setup standing in for the real cloud backend (ADR 0006) during early development: the Firebase Local Emulator Suite in a VM on Hooper (a Raspberry Pi), reachable only over the owner's Tailscale tailnet.
- [nutcache/](nutcache/) — NutCache source: Firebase config, Firestore/Storage security rules and indexes (and Cloud Functions once there are any), plus the dev-instance plumbing (`nutcache/dev-instance/`: VM provisioning, emulator service, and `deploy.sh`, run on Hooper). See [nutcache/README.md](nutcache/README.md).
- [docs/securing_nuts.md](docs/securing_nuts.md) — Go-live security ledger: every development-time security shortcut (e.g., relying on the Tailscale VPN for access control) and what must be done to secure it before the system goes live. See the Workflow rule below.
- [docs/nutcache_migration_debt.md](docs/nutcache_migration_debt.md) — NutCache migration ledger: every development-time decision to build something locally/client-side that an accepted ADR calls for NutCache to do centrally (e.g., querying external product databases directly from the phone instead of through NutCache), and what's required to migrate it once NutCache exists to host it. See the Workflow rule below.
- [docs/development-plan.md](docs/development-plan.md) — The four-phase development roadmap: every requirement in docs/requirements.md assigned to a phase (scope/sequencing only). Update the Traceability Summary whenever a requirement is added.
- [docs/test-plan.md](docs/test-plan.md) — The test plan: equipment/environment needed, per-phase setup, test cases (automated `AT#.#` / manual `MT#.#`), requirement-to-test-case traceability, and exit criteria. Keep this and development-plan.md's phase scope in sync when either changes.

## Documentation Standards (Dart/Flutter code)

- **Tool**: [`dartdoc`](https://dart.dev/tools/dartdoc) (the `dart doc` command, bundled with the Dart SDK) is the code documentation tool for this project — not Doxygen, which has no native Dart support. Generate docs from within `app/` with `dart doc .`; output goes to `app/doc/api` (gitignored — generated, not committed; regenerate on demand).
- **Every public class, method, getter/setter, field, and top-level function must have a `///` doc comment.** This is enforced by the `public_member_api_docs` lint, enabled in `app/analysis_options.yaml` — `flutter analyze` will flag any public member missing one. Private (`_`-prefixed) members and `@override` members (which inherit the superclass's doc) are exempt.
- **Every doc comment must include a `UREQS:` line** tracing the member to the requirement(s) in [docs/requirements.md](docs/requirements.md) it implements, e.g.:

  ```dart
  /// Matches a scanned product to an item on the active shopping list.
  ///
  /// Returns the best-matching item, or `null` if no candidate exceeds the
  /// confidence threshold.
  ///
  /// UREQS: LIST-2, LIST-3
  ShoppingListItem? matchProduct(Product product) { ... }
  ```

  If a member genuinely doesn't trace to any requirement (e.g., a pure utility, a framework-required override, scaffold placeholder code), write `UREQS: none` plus a short reason — the point is that the absence of a requirement link is a deliberate, visible statement, not a silent gap a reviewer has to guess about.
- **Why a plain `UREQS:` line and not a custom tag**: dartdoc (unlike Doxygen) has no mechanism for custom structured tags (no `@requirement`-style commands) — it renders whatever Markdown is in the `///` comment as-is. A conventionally-labeled line is the simplest thing that (a) reads fine in generated docs, (b) is trivially greppable (`grep -rn "UREQS:" app/lib`), and (c) needs no tooling investment before there's a real codebase to justify it.
- **Enforcement scope, honestly stated**: the analyzer lint guarantees *a* doc comment exists; it does not check that a `UREQS:` line is present or that the IDs it names are real. That check is a code-review responsibility for now. If missing/bogus UREQS references become a recurring problem once there's substantial code, consider a small script that greps all `.dart` files for `UREQS:` lines and validates each ID against `docs/requirements.md` — don't build that ahead of need.

## Workflow

- Architectural decisions are recorded as ADRs before/alongside implementation, not after the fact.
  - New ADRs start in `docs/adrs/Proposed/`.
  - Once decided, they move to `docs/adrs/Accepted/` or `docs/adrs/Rejected/` (see the ADR README for the full process).
- Use `docs/adrs/template.md` as the starting point for any new ADR.
- Requirements belong to accepted decisions, not proposed ones: derive/update [docs/requirements.md](docs/requirements.md) as part of accepting an ADR (moving it into `docs/adrs/Accepted/`), not while it's still in `Proposed/`.
  - Note: the initial batch of requirements (ADRs 0001-0012) was derived while those ADRs were still Proposed, ahead of this rule being adopted. No issues have surfaced from that, so it's being left as-is rather than reworked — but this is the exception, not the pattern to repeat.
- **Security debt goes in [docs/securing_nuts.md](docs/securing_nuts.md) when the decision is made.** Whenever a development decision relies on a protection that won't exist, or won't be enough, in production, add a `SEC-#` entry in the same change. Examples: VPN-only access, emulator auth bypasses, cleartext exceptions, test credentials, broad permissions, disabled checks. The entry says what we're doing now, why it's acceptable for development, and the concrete steps required to secure it before go-live. Don't defer this to later, and don't resolve an entry without recording how it was verified.
- **NutCache migration debt goes in [docs/nutcache_migration_debt.md](docs/nutcache_migration_debt.md) when the decision is made.** Whenever a development decision builds something locally/client-side that an accepted ADR envisions NutCache doing centrally (e.g., a mobile-side feature calling an external API directly because NutCache doesn't exist yet to host that call), add a `MIGRATE-#` entry in the same change. The entry says what we're doing now, why it's acceptable for now, and the concrete steps required to migrate it to NutCache. Don't defer this to later, and don't resolve an entry without recording how it was verified.
- Keep `docs/requirements.md` up to date as the project progresses — when an ADR is added, superseded, or its scope changes, revisit the requirements it produced.

## Reference Documents

- Requirements: [docs/requirements.md](docs/requirements.md)
- Development plan (4 phases, scope/sequencing): [docs/development-plan.md](docs/development-plan.md)
- Test plan (equipment, setup, test cases, exit criteria): [docs/test-plan.md](docs/test-plan.md)
- ADR index/process: [docs/adrs/README.md](docs/adrs/README.md)
- ADR template: [docs/adrs/template.md](docs/adrs/template.md)
- Go-live security ledger: [docs/securing_nuts.md](docs/securing_nuts.md)
- NutCache migration debt ledger: [docs/nutcache_migration_debt.md](docs/nutcache_migration_debt.md)
- Design notes: [docs/design/](docs/design/) (see [NutCache dev instance](docs/design/nutcache-dev-instance.md))
- Accepted ADRs:
  - [0001: Mobile App Framework](docs/adrs/Accepted/0001-mobile-app-framework.md)
  - [0002: Product Label Capture & Recognition Method](docs/adrs/Accepted/0002-product-label-capture-method.md)
  - [0003: On-Device AI Runtime](docs/adrs/Accepted/0003-on-device-ai-runtime.md)
  - [0004: Product-to-Shopping-List Matching Strategy](docs/adrs/Accepted/0004-product-shopping-list-matching-strategy.md)
  - [0005: Offline-First Local Storage & Sync](docs/adrs/Accepted/0005-offline-local-storage-and-sync.md)
  - [0006: Cloud Backend Platform](docs/adrs/Accepted/0006-cloud-backend-platform.md)
  - [0007: Cloud-Mobile Sync/API Protocol](docs/adrs/Accepted/0007-cloud-mobile-sync-api-protocol.md)
  - [0008: Price Label Capture Method](docs/adrs/Accepted/0008-price-label-capture-method.md)
  - [0009: Coupon Handling & Matching](docs/adrs/Accepted/0009-coupon-handling-and-matching.md)
  - [0010: Cross-Store Price Comparison by Locality](docs/adrs/Accepted/0010-cross-store-price-comparison.md)
  - [0011: Cloud Historical Pricing Data & Cross-User Sharing](docs/adrs/Accepted/0011-cloud-historical-pricing-and-sharing.md)
  - [0012: Barcode Matching Database](docs/adrs/Accepted/0012-barcode-matching-database.md)
  - [0013: Nutrition Label Reading & Goal Matching](docs/adrs/Accepted/0013-nutrition-label-reading-and-goal-matching.md)
  - [0014: Nutrition Plan & Biometric Goal Data Model](docs/adrs/Accepted/0014-nutrition-plan-and-biometric-goal-model.md)
  - [0015: Cloud/Local Processing Split for Nutrition Planning & Tracking](docs/adrs/Accepted/0015-cloud-local-split-nutrition-planning.md)
  - [0016: Recipe Creation, Import & Ingredient Nutrient Computation](docs/adrs/Accepted/0016-recipe-creation-import-and-nutrient-computation.md)
  - [0017: Cooking Method Effects on Nutritional Value](docs/adrs/Accepted/0017-cooking-method-nutrient-effects.md)
  - [0018: Health & Fitness Tracker Integration](docs/adrs/Accepted/0018-health-fitness-tracker-integration.md)
  - [0019: Biometric & Intake Tracking History and Multi-Source Reconciliation](docs/adrs/Accepted/0019-tracking-history-and-source-reconciliation.md)
  - [0020: HIPAA & Health Data Privacy Compliance](docs/adrs/Accepted/0020-health-data-privacy-and-hipaa.md)
  - [0021: Healthcare Provider Data Sharing Interface](docs/adrs/Accepted/0021-healthcare-provider-data-sharing-interface.md)
  - [0022: Cross-User Data Sharing — Scope & Governance Model](docs/adrs/Accepted/0022-cross-user-data-sharing-scope-model.md)
  - [0023: Recipe Sharing & Discovery](docs/adrs/Accepted/0023-recipe-sharing-and-discovery.md)
  - [0024: Recipe Copyright & Contributor Liability](docs/adrs/Accepted/0024-recipe-copyright-and-contributor-liability.md)
  - [0025: Nutrition Data Trust & Validation Model](docs/adrs/Accepted/0025-nutrition-data-trust-and-validation-model.md)
