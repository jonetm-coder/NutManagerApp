# Phased Development Plan

This plan sequences the requirements in [docs/requirements.md](requirements.md) into four development phases, each ending in a working, testable increment. Phasing follows dependency order and value delivery: prove the core on-device loop first, then wire up the cloud/multi-device backend, then layer on economic features (pricing/coupons) and the first slice of nutrition matching, then build out the full nutrition/health/sharing system. All 101 requirements currently in `docs/requirements.md` are assigned to exactly one phase below (see the Traceability Summary at the end).

Every requirement ID referenced here is the source of truth in [docs/requirements.md](requirements.md) — this document doesn't restate acceptance criteria in full, only enough to make each phase self-contained to read. **Test plans, test equipment, setup, and exit criteria live in [docs/test-plan.md](test-plan.md)**, not here — this document is scope and sequencing only.

## Guiding Principles

- **Each phase ends with something real to test**, not just code merged — a phase isn't "done" until its test plan has been executed and its exit criteria met.
- **Later phases build on earlier ones without reworking them.** Phase 1 deliberately uses a small local seed catalog instead of the real shared barcode/nutrition databases, but the on-device data model is the same one Phase 2 wires up to the cloud — Phase 2 shouldn't require rebuilding Phase 1.
- **Must Have requirements gate a phase; Should Have and Nice to Have do not.** A phase can be considered functionally complete with its Must Haves passing even if a Should Have slips — track slipped items explicitly rather than silently dropping them.
- **The two explicit legal-review gates (PRIV-5, RCOPY-4) are real ship-blockers**, not just requirements to implement code against — Phase 4's exit criteria call this out separately from the automated/manual test results.

## Phase 0 — Foundation (Already Complete)

Not one of the four requested phases, but worth noting as the base everything below builds on: the Flutter app scaffold (`app/`) and the dartdoc/`public_member_api_docs`/UREQS documentation convention are already in place. The NutCache dev instance (the Firebase Local Emulator Suite in a VM on Hooper, reachable over Tailscale) is designed in [docs/design/nutcache-dev-instance.md](design/nutcache-dev-instance.md) but not yet stood up; it must be running before Phase 2, which is where the app first actually talks to NutCache.

---

## Phase 1 — Core Scanning & Local Shopping List (Single Device)

**Goal:** Prove the fundamental in-store loop — scan a product, identify it, match it to a shopping list, manage the basket — works end to end on one Android device, fully offline, before any cloud/multi-device/backend complexity is introduced. Product identification is barcode-only in this phase (OCR and image-classification fallbacks are Phase 2); the shopping list and product catalog are local-only, seeded with a small hand-picked dataset rather than the real shared databases.

### Requirements in Scope

| ID | Gist | Priority |
|---|---|---|
| PLAT-1 | Runs on Android | Must Have |
| PLAT-3 | Camera-based scanning as core input | Must Have |
| SCAN-1 | Identify product by barcode | Must Have |
| SCAN-4 | Identification works fully offline | Must Have |
| SCAN-7 | Prompt for confirmation on low-confidence match | Must Have |
| SCAN-8 | Manual identify/correct fallback | Must Have |
| LIST-2 | Match scanned product to shopping list item | Must Have |
| LIST-3 | Confirm ambiguous matches | Must Have |
| LIST-4 | Remove an item from the basket | Must Have |
| LIST-5 | Manually add an unresolved list item | Should Have |
| LIST-6 | Category/synonym mapping to support matching | Should Have |
| SYNC-1 | Cache list + catalog subset locally (local-only in this phase — no cloud source yet) | Must Have |
| SYNC-3 | No in-store action blocked by lack of connectivity | Must Have |
| LSTORG-1 | Multiple named shopping lists | Must Have |
| LSTORG-2 | Add a planned item directly to a list | Must Have |
| LSTORG-3 | Quantity on list items/basket entries, defaulting to 1 | Must Have |
| LSTORG-4 | Archive a list; browse archived lists read-only | Must Have |
| LSTORG-5 | Top-level nav separates Shopping Lists from other sections | Must Have |
| PRICE-1 | Capture price via shelf-tag scan | Must Have |
| PRICE-2 | Manual price entry fallback | Must Have |
| PRICE-3 | Record price with product/store/timestamp | Must Have |
| PRICE-10 | Recognize per-unit vs. total price | Must Have |
| PLOOKUP-1 | "Check Products": external lookup by name to pre-populate catalog | Should Have |
| PLOOKUP-2 | Scan-to-add from home via local/history/external resolution waterfall | Should Have |
| PLOOKUP-3 | Automatic background barcode lookup/cache when an item is added to a list | Should Have |

**Pulled forward from later phases:** LSTORG-1..5, PRICE-1/2/3/10, and PLOOKUP-1/2/3 were not in the original four-phase scope above but were built directly into the Phase 1 app, ahead of schedule, in response to user feedback during Phase 1 development. PRICE-1/2/3/10 were originally scoped for Phase 3 (price capture only makes sense once there's a basket to attach prices to, which Phase 1 already has); PRICE-4..9 (comparison, sharing) remain in Phase 3 as originally planned, since those genuinely need the cloud-side shared pricing dataset. PLOOKUP-1/2/3 are an accelerated, phone-only interim version of what Phase 2's BC-1/SCAN-9/SCAN-10 (a centrally-built, crowdsourced shared barcode database via NutCache) formally calls for — implemented now by querying external open product databases directly from the phone instead, since NutCache doesn't exist yet. This is a deliberate, tracked architecture deviation, not an oversight: see [docs/nutcache_migration_debt.md](nutcache_migration_debt.md) (MIGRATE-1) for what moving it to NutCache will require. Per this plan's own guiding principle, Phase 2 should be able to replace the external-lookup implementation behind `ProductLookupService` without reworking `ProductResolutionService`'s waterfall or any screen that calls it. PLOOKUP-3 specifically closes a real gap found during on-device testing: the in-list "Scan" action (SCAN-1) deliberately only checks the local catalog, so it never found a real packaged product (e.g. Thomas's English Muffins) until *something* had populated the catalog with its real barcode — PLOOKUP-3 does that automatically, in the background, at the moment the item is added to a list, rather than requiring the user to remember to tap "Check Products."

**Test plan, equipment, and exit criteria:** [docs/test-plan.md § Phase 1](test-plan.md#phase-1--core-scanning--local-shopping-list)

---

## Phase 2 — Cloud Backend, Multi-Device Household Sync, Barcode DB, Full Capture

**Goal:** Replace Phase 1's local-only list/catalog with the real cloud-backed model: NutCache on Firebase (via the NutCache dev instance on Hooper, per [docs/design/nutcache-dev-instance.md](design/nutcache-dev-instance.md)) as the source of truth for shopping lists, household multi-user access, the offline outbox/sync pattern, and the shared barcode database. Also fill in the capture-method richness deferred from Phase 1 (OCR and image-classification fallbacks, variable-weight barcode parsing, RCN store-scoping).

### Requirements in Scope

| ID | Gist | Priority |
|---|---|---|
| LIST-1 | Download household shopping list from cloud | Must Have |
| LIST-7 | Multi-member household list access | Must Have |
| SYNC-2 | Queue offline changes, apply on reconnect | Must Have |
| SYNC-4 | Conflict resolution (last-write-wins) | Should Have |
| CLOUD-1 | Cloud stores nutrition/recipes/lists per household | Must Have |
| CLOUD-2 | Household data access restricted to members | Must Have |
| CLOUD-3 | Server-side computation not trusting client-derived data | Should Have |
| CLOUD-4 | Backend access behind an app-internal abstraction layer | Should Have |
| BC-1 | Barcode DB: global + store-scoped ranges | Must Have |
| BC-2 | Store-scoped mappings isolated per store | Must Have |
| BC-3 | Crowdsourced barcode correction with abuse mitigation | Should Have |
| BC-4 | Barcode DB subset synced for offline lookup | Must Have |
| SCAN-2 | OCR fallback identification | Must Have |
| SCAN-3 | Image-classification fallback (produce, etc.) | Should Have |
| SCAN-5 | Distinguish global vs. RCN barcode ranges | Must Have |
| SCAN-6 | Parse variable-weight/price-embedded barcodes | Must Have |
| SCAN-9 | Contribute barcode corrections | Should Have |
| SCAN-10 | Barcode DB seeded from open data | Should Have |

**Test plan, equipment, and exit criteria:** [docs/test-plan.md § Phase 2](test-plan.md#phase-2--cloud-backend-multi-device-household-sync-barcode-db-full-capture)

---

## Phase 3 — Pricing, Coupons & In-Store Nutrition Goal Matching

**Goal:** Add the economic in-store features (price comparison/sharing, coupons) and the first slice of the nutrition domain — reading a product's Nutrition Facts panel and checking it against a household member's basic nutrient targets, in real time, offline. Full nutrition *planning* (editing a rich plan, biometric goals, recipes, tracking history) is still Phase 4; this phase only builds the minimum goal data needed for the in-store check to mean something (a flat set of nutrient targets per member). Price *capture* itself (PRICE-1/2/3/10) was pulled forward into Phase 1 — see that phase's "Pulled forward" note; this phase adds cross-store comparison and the shared/cross-household pricing dataset on top of it.

### Requirements in Scope

| ID | Gist | Priority |
|---|---|---|
| PRICE-4 | Compare price across nearby stores | Should Have |
| PRICE-5 | Configure comparison radius/stores | Nice to Have |
| PRICE-6 | Offline: show last-synced price data with timestamp | Should Have |
| PRICE-7 | Shared pricing dataset, no PII | Must Have |
| PRICE-8 | Opt out of contributing price data | Must Have |
| PRICE-9 | Basic validation of submitted price data | Should Have |
| COUP-1 | Capture printed coupon via barcode | Must Have |
| COUP-2 | Manual electronic coupon entry | Should Have |
| COUP-3 | Match coupon to product with restrictions | Must Have |
| COUP-4 | Surface coupon for confirmation, don't auto-apply | Must Have |
| COUP-5 | Same-category near-miss coupon warning | Should Have |
| COUP-6 | Coupons as household-private synced data | Must Have |
| NUTL-1 | In-store per-member goal-fit indicator, offline | Must Have |
| NUTL-2 | OCR fallback for unknown product nutrition | Must Have |
| NUTL-3 | Contribute nutrition data corrections | Should Have |
| NUTL-4 | Higher corroboration bar for nutrition corrections | Should Have |
| PLAN-1 | Per-member nutrient targets (min/max/range) | Must Have |
| PLAN-4 | Nutrition goals as household-private, per-member data | Must Have |
| NPROC-2 | Local read-only snapshot of active goals for offline matching | Must Have |

**Test plan, equipment, and exit criteria:** [docs/test-plan.md § Phase 3](test-plan.md#phase-3--pricing-coupons--in-store-nutrition-goal-matching)

---

## Phase 4 — Full Nutrition Planning, Tracking, Cross-User Sharing & Compliance ("Fully Integrated System")

**Goal:** Complete the nutrition/health domain (full plan editing, biometric goals and their versioning, recipes with cooking-method-adjusted nutrient computation, append-only tracking history), add cross-user recipe sharing with its governance and legal gates, and bring iOS to parity — the milestone at which the system matches the full scope of the accepted ADRs.

### Requirements in Scope

| ID | Gist | Priority |
|---|---|---|
| PLAN-2 | Per-member biometric goals with trend | Must Have |
| PLAN-3 | Dated history of goal changes | Must Have |
| NPROC-1 | Server-side recipe/cooking-method computation | Should Have |
| RECIPE-1 | Create a recipe (title/ingredients/servings/steps) | Must Have |
| RECIPE-2 | Compute recipe nutrients incl. calories | Must Have |
| RECIPE-3 | Link ingredient to branded product | Nice to Have |
| RECIPE-4 | Flag ambiguous unit conversions | Should Have |
| RECIPE-5 | Import recipe from structured-markup URL | Should Have |
| RECIPE-6 | Manual recipe entry fallback | Must Have |
| RECIPE-7 | Log timestamped, member-attributed intake | Must Have |
| COOK-1 | Adjust nutrients for cooking method | Should Have |
| COOK-2 | Flag when no cooking adjustment data available | Must Have |
| COOK-3 | Tag/confirm detected cooking method per step | Should Have |
| TRACK-1 | Manual biometric entry, any household member | Must Have |
| TRACK-2 | Every measurement recorded with a source | Must Have |
| TRACK-3 | Data model ready for future tracker integration | Should Have |
| TRACK-4 | Append-only history, corrections supersede | Must Have |
| TRACK-5 | Source-precedence rule (tracker over manual) | Should Have |
| TRACK-6 | Adherence evaluated against goal-version-at-the-time | Must Have |
| PRIV-1 | Health data logically separated from other app data | Must Have |
| PRIV-2 | Distinct opt-in for health data collection | Must Have |
| PRIV-3 | Export/delete health data | Must Have |
| PRIV-4 | Encryption + audit logging for health data | Must Have |
| PRIV-5 | **Legal review gate** before provider-sharing ships | Must Have |
| PROV-1 | Export plan/goals/history as FHIR bundle | Should Have |
| PROV-2 | Select categories/date range per share | Must Have |
| PROV-3 | Explicit per-instance consent per share | Must Have |
| SHAREGOV-1 | Shared-data-type classification checklist applied | Must Have |
| RSHARE-1 | Recipes private by default; explicit share action | Must Have |
| RSHARE-2 | Attribution on shared recipes | Must Have |
| RSHARE-3 | Fork-on-save, not live reference | Must Have |
| RSHARE-4 | Revisions publish as new linked version | Should Have |
| RSHARE-5 | Search/browse shared recipes | Should Have |
| RSHARE-6 | Report a shared recipe | Must Have |
| RCOPY-1 | Shared recipe stores functional core, not narrative | Must Have |
| RCOPY-2 | Contributor attestation before publishing | Must Have |
| RCOPY-3 | Notice-and-takedown process | Must Have |
| RCOPY-4 | **Legal review gate** before public recipe sharing ships | Must Have |
| PLAT-2 | Runs on iOS | Should Have |

**Test plan, equipment, and exit criteria:** [docs/test-plan.md § Phase 4](test-plan.md#phase-4--full-nutrition-planning-tracking-cross-user-sharing--compliance)

---

## Traceability Summary

| Phase | Requirement IDs | Count |
|---|---|---|
| 1 | PLAT-1, PLAT-3, SCAN-1, SCAN-4, SCAN-7, SCAN-8, LIST-2, LIST-3, LIST-4, LIST-5, LIST-6, SYNC-1, SYNC-3, LSTORG-1..5, PRICE-1, PRICE-2, PRICE-3, PRICE-10, PLOOKUP-1, PLOOKUP-2, PLOOKUP-3 | 25 |
| 2 | LIST-1, LIST-7, SYNC-2, SYNC-4, CLOUD-1, CLOUD-2, CLOUD-3, CLOUD-4, BC-1, BC-2, BC-3, BC-4, SCAN-2, SCAN-3, SCAN-5, SCAN-6, SCAN-9, SCAN-10 | 18 |
| 3 | PRICE-4..9, COUP-1..6, NUTL-1..4, PLAN-1, PLAN-4, NPROC-2 | 19 |
| 4 | PLAN-2, PLAN-3, NPROC-1, RECIPE-1..7, COOK-1..3, TRACK-1..6, PRIV-1..5, PROV-1..3, SHAREGOV-1, RSHARE-1..6, RCOPY-1..4, PLAT-2 | 39 |
| **Total** | | **101** |

If a new requirement is added to `docs/requirements.md` later, assign it to a phase here in the same edit — this table should stay a complete accounting of every requirement, not just the ones convenient to phase.
