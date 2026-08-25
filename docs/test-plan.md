# Test Plan

This document owns **how each requirement is verified**. [docs/development-plan.md](development-plan.md) owns *what* is being built and *when* (the four phases and their scope) — it links here for the actual test plan rather than duplicating it. Every requirement ID referenced below is defined in [docs/requirements.md](requirements.md).

Test cases are numbered `AT<phase>.<n>` (automated) and `MT<phase>.<n>` (manual), so any requirement, test run, or bug report can point at an exact case rather than a vague phase-level description.

## Test Equipment & Environment

Equipment needed across all four phases. Each phase's section below states which of these are actually needed for that phase — earlier phases need less.

### Devices

| ID | Item | Notes |
|---|---|---|
| EQ-D1 | One physical Android phone or tablet | Required from Phase 1 on. Camera-dependent and true offline (airplane mode) behavior cannot be validated on an emulator — see Phase 1 setup. |
| EQ-D2 | A second physical Android device | Required from Phase 2 on, for multi-device household sync testing. Doesn't need to match EQ-D1's model. |
| EQ-D3 | A physical iOS device, plus a Mac or cloud Mac CI runner (e.g., Codemagic, GitHub Actions macOS runner) to build for it | Required only for Phase 4 (PLAT-2). Per [ADR 0001](adrs/Accepted/0001-mobile-app-framework.md) and [README.md](../README.md), iOS builds cannot be produced from the Kali Linux dev machine. |
| EQ-D4 | Android emulator (AVD), already available per [README.md](../README.md) | Useful for early UI iteration and non-camera automated tests, but is **not** a substitute for EQ-D1/EQ-D2 in any test involving the camera, real multi-device timing, or genuine offline behavior. |

### Network & Backend

| ID | Item | Notes |
|---|---|---|
| EQ-N1 | Home Wi-Fi network reachable by all test devices | Needed from Phase 2 on, so devices can reach Hooper. |
| EQ-N2 | Hooper powered on, VM running, Firebase Local Emulator Suite started | Per [docs/design/hooper-local-dev-backend.md](design/hooper-local-dev-backend.md). Needed from Phase 2 on. **Phase 1 tests should be run with Hooper deliberately off or unreachable** — not just airplane mode on the device — to catch any accidental network dependency airplane mode alone might not reveal (e.g., a background sync attempt on a different network path). |
| EQ-N3 | Ability to toggle connectivity (airplane mode) on each test device on demand | Needed from Phase 1 on. |

### Physical Test Materials

| ID | Item | Notes |
|---|---|---|
| EQ-P1 | Barcode test fixture set: generated barcode images (digital) and printed copies of the same codes | Phase 1 on. See "Barcode Test Fixtures" below — generated, not photographed, so the digital and printed versions are guaranteed identical. A standard home printer is sufficient. |
| EQ-P2 | A handful of real grocery products with known UPCs, recorded into the seed catalog | Phase 1 on, as a supplement to EQ-P1 for real-world-condition checks (see MT1.7). |
| EQ-P3 | Mocked shelf price tags, including at least one deliberately handwritten/hard-to-read example | Phase 3. |
| EQ-P4 | Sample coupons with a scannable barcode, including at least one with an expiration date and a minimum-quantity restriction | Phase 3. |
| EQ-P5 | Sample Nutrition Facts panel images/printouts, including at least one for a product deliberately absent from the seed/shared nutrition database | Phase 3. |

### Test Accounts & Data

| ID | Item | Notes |
|---|---|---|
| EQ-A1 | At least two distinct household test accounts | Phase 2 on (cross-household isolation, CLOUD-2) and Phase 4 (recipe sharing, RSHARE-*). Created against Hooper's Firebase Auth emulator, not a real Firebase project. |
| EQ-A2 | A version-controlled seed product catalog (barcode → product, later + nutrition data) | Phase 1 on, extended in later phases. Lives alongside the app source so it's reviewable and reproducible, not assembled ad hoc per test run. |

### Software & Tooling

| ID | Item | Notes |
|---|---|---|
| EQ-S1 | Flutter/Android SDK dev environment | Per [README.md](../README.md) — already set up. |
| EQ-S2 | `integration_test` Flutter package, configured in `app/` | Needed starting Phase 1 for on-device fixture-based tests (see AT1.2). Not yet added to `app/pubspec.yaml` as of this writing — add it when Phase 1 automated tests are implemented. |
| EQ-S3 | Firebase Emulator Suite UI (bundled with the suite running on Hooper) | Phase 2 on — used to verify backend state directly, not just trust the app's own display of it. |
| EQ-S4 | A barcode-image generation tool or library | Phase 1 — for producing EQ-P1's fixtures. Specific library TBD when Phase 1 fixtures are built; any tool producing standard UPC-A/EAN-13 images is sufficient. |

---

## Phase 1 — Core Scanning & Local Shopping List

**Scope reference:** [development-plan.md § Phase 1](development-plan.md#phase-1--core-scanning--local-shopping-list-single-device)

### Setup

- Equipment: EQ-D1, EQ-N3, EQ-P1, EQ-P2, EQ-A2, EQ-S2, EQ-S4.
- Hooper (EQ-N2) is **not** used in this phase — leave it off or firewalled from the test device to make sure nothing in Phase 1 accidentally depends on it.
- Seed catalog (EQ-A2) populated with entries for every EQ-P1 fixture code plus the EQ-P2 real products, including at least one deliberate near-duplicate pair (e.g., "whole milk" and "2% milk") to exercise ambiguous matching.
- Barcode fixtures (EQ-P1) generated once via EQ-S4 and committed to `app/test/fixtures/barcodes/`; printed copies made from the same files.

### Requirements Tested

| ID | Requirement Gist | Verified By |
|---|---|---|
| PLAT-1 | Runs on Android | MT1.1–MT1.6 (executed on EQ-D1) |
| PLAT-3 | Camera-based scanning | MT1.1, MT1.7 |
| SCAN-1 | Identify product by barcode | AT1.1, AT1.2, MT1.1 |
| SCAN-4 | Identification works offline | AT1.1, MT1.1 |
| SCAN-7 | Confirm on low confidence | AT1.4, MT1.4 |
| SCAN-8 | Manual identify/correct fallback | AT1.4, MT1.2 |
| LIST-2 | Match scanned product to list item | AT1.3, MT1.3 |
| LIST-3 | Confirm ambiguous matches | AT1.3, MT1.4 |
| LIST-4 | Remove basket item | AT1.5, MT1.5 |
| LIST-5 | Manually add unresolved item | AT1.5, MT1.6 |
| LIST-6 | Category/synonym mapping | AT1.3 |
| SYNC-1 | Local cache of list + catalog | AT1.6 |
| SYNC-3 | No action blocked offline | MT1.1, MT1.5, MT1.6 |

### Automated Test Cases

| ID | Description | Type |
|---|---|---|
| AT1.1 | Barcode→Product lookup, pure logic: known code resolves correctly; unknown code returns "not found"; empty/malformed input handled without crashing. No camera, image, or device dependency. | Unit |
| AT1.2 | Feed each `app/test/fixtures/barcodes/*.png` fixture to the ML Kit decoder via `InputImage.fromFilePath(...)` on-device; assert the decoded value and the resolved product match the seed catalog for every fixture. | Integration (on-device) |
| AT1.3 | Matching engine: exact-ID match, normalized-text match, category/synonym fallback (LIST-6), and the confidence threshold that triggers confirmation (feeds AT1.4's UI trigger condition). | Unit |
| AT1.4 | Scan-result confirmation UI renders when AT1.3's confidence threshold isn't met; manual-correction flow (SCAN-8) accepts a corrected product and updates state accordingly. | Widget |
| AT1.5 | Basket state transitions: add via scan, add manually (LIST-5), remove (LIST-4), and the "returns to unfulfilled" behavior when a list-sourced item is removed. | Unit |
| AT1.6 | Local cache (SYNC-1) persists the seed list/catalog across an app restart with no network available. | Integration (on-device) |
| AT1.7 | `flutter analyze` clean; `public_member_api_docs` satisfied; every new public member has a `UREQS:` line tracing to one of this phase's requirement IDs (or `UREQS: none` with reason). | Static analysis |

### Manual Test Cases

Run on EQ-D1 with Hooper unreachable (per Setup, above) unless stated otherwise.

| ID | Steps | Expected Result |
|---|---|---|
| MT1.1 | Enable airplane mode. Scan each EQ-P1 printed fixture (or an EQ-P2 real product). | Each resolves to the correct product; no network call attempted (confirm via a network-access assertion/mock, not just visual success). |
| MT1.2 | Scan a barcode not in the seed catalog. | App prompts for manual identification (SCAN-8) rather than failing silently. |
| MT1.3 | Scan a product matching exactly one list item. | Item is added to the basket with no confirmation prompt. |
| MT1.4 | Scan a product where two list items are close matches (e.g., the "whole milk"/"2% milk" pair from Setup). | App asks the user to pick (LIST-3), doesn't guess. |
| MT1.5 | Remove a basket item that originated from the list. | Item returns to "unfulfilled" on the list view rather than just disappearing. |
| MT1.6 | Manually add an item the scan flow didn't resolve. | Item appears in the basket. |
| MT1.7 | Using EQ-P2 real products (not the flat-printed EQ-P1 fixtures), scan under real-world conditions the fixtures can't cover: a slightly crumpled/curved label, low light, and an angled scan. | App either reads correctly or degrades to "couldn't read, try again"/manual fallback — never silently misreads a code. |

### Exit Criteria

- AT1.1–AT1.7 all passing; MT1.1–MT1.7 executed once on EQ-D1 with no failures.
- Any Should Have requirement not completed (LIST-5, LIST-6) is explicitly logged as carried into Phase 2, not silently dropped.

---

## Phase 2 — Cloud Backend, Multi-Device Household Sync, Barcode DB, Full Capture

**Scope reference:** [development-plan.md § Phase 2](development-plan.md#phase-2--cloud-backend-multi-device-household-sync-barcode-db-full-capture)

### Setup

- Equipment: EQ-D1, EQ-D2, EQ-N1, EQ-N2, EQ-N3, EQ-A1, EQ-A2, EQ-S3.
- Hooper up and running, both test devices on the same LAN and able to reach it.
- Two household accounts created in the emulator's Auth (EQ-A1): the "test household" both devices belong to, and a second, unrelated household for the isolation check (MT2.3).
- Seed catalog (EQ-A2) extended with: at least one barcode in a globally-assigned range, at least one in an RCN range associated with two *different* fake stores in the fixture data, and at least one variable-weight-style code with two different embedded-weight values for the same underlying product.

### Requirements Tested

| ID | Requirement Gist | Verified By |
|---|---|---|
| LIST-1 | Download household list from cloud | MT2.1 |
| LIST-7 | Multi-member household access | MT2.1 |
| SYNC-2 | Offline queue, apply on reconnect | AT2.1, MT2.2 |
| SYNC-4 | Conflict resolution | AT2.2 |
| CLOUD-1 | Cloud stores per-household data | AT2.1 |
| CLOUD-2 | Household data access restricted | AT2.1, MT2.3 |
| CLOUD-3 | Server-side computation, not client-trusted | AT2.1 (rules test) |
| CLOUD-4 | Backend behind app-internal abstraction | Code review (not independently testable at runtime) |
| BC-1 | Barcode DB: global + store-scoped | AT2.3, MT2.7 |
| BC-2 | Store-scoped isolation | AT2.3, MT2.7 |
| BC-3 | Crowdsourced correction, abuse mitigation | Deferred — see note below |
| BC-4 | Barcode DB subset synced offline | AT2.1 |
| SCAN-2 | OCR fallback | AT2.4, MT2.4 |
| SCAN-3 | Image-classification fallback | AT2.4, MT2.5 |
| SCAN-5 | Global vs. RCN range distinction | AT2.3, MT2.7 |
| SCAN-6 | Variable-weight barcode parsing | AT2.3, MT2.6 |
| SCAN-9 | Contribute barcode corrections | Deferred — see note below |
| SCAN-10 | Seeded from open data | Verified at data-sourcing time, not a runtime test |

*Note on BC-3/SCAN-9:* both are Should Have and describe a crowdsourcing/correction workflow that only becomes meaningfully testable once there's a real population of contributors and existing entries to correct. For Phase 2, verify the submission and storage mechanism works (a contributed correction is written and readable), but full abuse-mitigation behavior (multi-contributor corroboration thresholds) is out of scope for this phase's exit criteria — log it explicitly as a Phase 2 carryover rather than blocking on it.

### Automated Test Cases

| ID | Description | Type |
|---|---|---|
| AT2.1 | Against the Hooper emulator: list CRUD (CLOUD-1), a member reading/writing the household's own data succeeds (CLOUD-2 positive case), the offline outbox drains correctly once connectivity returns (SYNC-2), and the barcode DB subset (BC-4) is present in local cache after a sync. | Integration (on-device + emulator) |
| AT2.2 | Two simulated clients edit the same list item while both offline, then both reconnect; assert the last-write-wins outcome is deterministic and no data is silently dropped or duplicated. | Integration (emulator) |
| AT2.3 | Barcode classifier unit tests: known global-range codes, known RCN-range codes (BC-1/BC-2/SCAN-5), and variable-weight code parsing extracting the correct stable item reference regardless of embedded weight/price (SCAN-6). | Unit |
| AT2.4 | OCR fallback (SCAN-2) and image-classification fallback (SCAN-3) resolve a fixture image with no barcode to the correct product/category respectively; both reuse Phase 1's "low confidence → confirm" UI path. | Integration (on-device) |
| AT2.5 | Firestore security rules test suite: a non-member request against another household's data is rejected at the rules layer (CLOUD-2), and a client cannot write into a field intended to be server-computed only (CLOUD-3). | Rules unit tests (Firebase emulator's rules-unit-testing library) |

### Manual Test Cases

| ID | Steps | Expected Result |
|---|---|---|
| MT2.1 | On EQ-D1 (household member A), add an item to the shared list. Check EQ-D2 (household member B, same household). | Item appears on EQ-D2 after sync (LIST-1, LIST-7). |
| MT2.2 | Put EQ-D1 in airplane mode, mark three items found, then restore connectivity. | All three changes appear in the Hooper emulator UI (EQ-S3), not just in the app's own display. |
| MT2.3 | Attempt to open the test household's list while signed into the second, unrelated household account (EQ-A1). | Access is rejected. |
| MT2.4 | Scan a product with no barcode, or a covered/damaged one. | OCR fallback resolves it. |
| MT2.5 | Scan an item with no barcode and no legible text (e.g., a piece of produce). | Image-classification fallback proposes a category for confirmation. |
| MT2.6 | Scan two differently-weighted packages of the same variable-weight product (e.g., deli meat). | Both resolve to the same product identity. |
| MT2.7 | Scan the RCN-range fixture code associated with "Store A"; then, in a fresh session context representing "Store B," scan the identical numeric code. | App does **not** treat it as the same product across stores. |

### Exit Criteria

- AT2.1–AT2.5 and MT2.1–MT2.7 all passing against Hooper.
- The Firestore security rules suite (part of AT2.5) passes independently — CLOUD-2 is not considered met on the strength of client-side behavior alone.
- BC-3/SCAN-9 logged as carried forward per the note above; any other incomplete Should Have item logged the same way.

---

## Phase 3 — Pricing, Coupons & In-Store Nutrition Goal Matching

**Scope reference:** [development-plan.md § Phase 3](development-plan.md#phase-3--pricing-coupons--in-store-nutrition-goal-matching)

### Setup

- Equipment: EQ-D1, EQ-N2, EQ-N3, EQ-P3, EQ-P4, EQ-P5, EQ-A1.
- At least one nutrient target configured for a test household member before testing begins (needed for NUTL-1 to have something to evaluate against).
- At least one coupon pre-loaded for a specific seed-catalog product, with an expiration date and minimum-quantity restriction set, to exercise COUP-3's restriction logic.

### Requirements Tested

| ID | Requirement Gist | Verified By |
|---|---|---|
| PRICE-1 | Capture price via shelf-tag scan | AT3.1, MT3.1 |
| PRICE-2 | Manual price entry fallback | AT3.1, MT3.2 |
| PRICE-3 | Record price with product/store/timestamp | AT3.1, MT3.1 |
| PRICE-4 | Compare price across stores | MT3.8 |
| PRICE-5 | Configure comparison radius/stores | MT3.8 |
| PRICE-6 | Offline: last-synced price + timestamp | MT3.9 |
| PRICE-7 | Shared pricing, no PII | AT3.5 |
| PRICE-8 | Opt out of price contribution | AT3.5 |
| PRICE-9 | Basic validation of submitted prices | Deferred — see note below |
| COUP-1 | Capture printed coupon via barcode | AT3.1, MT3.3 |
| COUP-2 | Manual electronic coupon entry | MT3.3 (alternate path) |
| COUP-3 | Coupon restriction matching | AT3.2 |
| COUP-4 | Surface, don't auto-apply | MT3.3 |
| COUP-5 | Same-category near-miss warning | AT3.3, MT3.4 |
| COUP-6 | Household-private, synced coupons | MT2.1-style check, re-run for coupons |
| NUTL-1 | Offline per-member goal-fit indicator | AT3.4, MT3.5 |
| NUTL-2 | OCR fallback for unknown nutrition | MT3.6 |
| NUTL-3 | Contribute nutrition corrections | Deferred — see note below |
| NUTL-4 | Higher corroboration bar for nutrition | Deferred — see note below |
| PLAN-1 | Per-member nutrient targets | AT3.4 |
| PLAN-4 | Nutrition goals as household-private data | Covered by Phase 2's CLOUD-2 rules suite, extended to the goals collection |
| NPROC-2 | Local snapshot of active goals for offline matching | AT3.6, MT3.7 |

*Note on PRICE-9/NUTL-3/NUTL-4:* these describe crowdsourced-data quality mechanisms (outlier detection, corroboration thresholds) that need a realistic volume of shared data to meaningfully test, similar to BC-3 in Phase 2. Verify the submission pathway works; log full validation-logic testing as carried forward until there's enough real data to exercise it meaningfully.

### Automated Test Cases

| ID | Description | Type |
|---|---|---|
| AT3.1 | Shelf-tag and coupon-barcode OCR/parsing (PRICE-1, COUP-1) against a fixture set of sample label images, including one deliberately illegible price tag that must trigger the manual-entry fallback (PRICE-2) rather than a wrong guess. | Integration (on-device) |
| AT3.2 | Coupon restriction logic (COUP-3): separate passing/failing cases for expiration, quantity threshold, and variant exclusion. | Unit |
| AT3.3 | Same-category near-miss warning (COUP-5): coupon on file for product A in category C; scanning product B in category C fires the warning and does not auto-apply anything. | Unit |
| AT3.4 | Goal-matching evaluator (NUTL-1): given a nutrient target (PLAN-1) and a product's nutrition data, verify pass/fail/boundary cases for min-only, max-only, and range target types. | Unit |
| AT3.5 | Against Hooper: a price observation submitted with opt-out enabled (PRICE-8) never carries identifying contributor info in the shared collection (PRICE-7); one submitted without opt-out carries only the opaque contributor token, never personal identity. | Integration (emulator) |
| AT3.6 | NPROC-2's local goal snapshot updates correctly after an online goal edit, and remains correct/usable after connectivity is subsequently disabled. | Integration (on-device) |

### Manual Test Cases

| ID | Steps | Expected Result |
|---|---|---|
| MT3.1 | Scan a clearly printed shelf price tag (EQ-P3). | Price captured, associated with correct product/store/timestamp (PRICE-3). |
| MT3.2 | Scan the deliberately handwritten/hard-to-read price tag from EQ-P3. | OCR either extracts it correctly or cleanly falls back to manual entry — never silently records a wrong price. |
| MT3.3 | With a coupon (EQ-P4) on file for a specific product, scan that exact product. | Coupon surfaced for confirmation, not auto-applied (COUP-4). |
| MT3.4 | With the same coupon on file, scan a *different* product in the same category. | Near-miss warning appears, clearly naming the coupon and the original product. |
| MT3.5 | With a nutrient target configured (e.g., "sodium ≤ 500 mg per serving"), scan a product exceeding it, in airplane mode. | Clear per-member warning shown, fully offline. |
| MT3.6 | Scan a product with no nutrition data cached locally or on Hooper (use EQ-P5's "absent from database" sample). | App prompts to scan the Nutrition Facts panel (NUTL-2); a low-quality/illegible panel scan does not silently produce a wrong pass/fail result. |
| MT3.7 | With connectivity off throughout, re-check the goal-fit indicator from MT3.5 without having made any new edits. | Indicator still reflects the previously-set goal correctly (NPROC-2). |
| MT3.8 | (Requires at least two distinct "store" entries in test price data.) Open the price comparison view for a product with observations at both stores. | Both stores' prices shown; adjusting the configurable radius/store set (PRICE-5) changes what's included. |
| MT3.9 | Disable connectivity, then open the price comparison view again. | Last-synced data shown with a visible timestamp, not a blank/broken state. |

### Exit Criteria

- AT3.1–AT3.6 and MT3.1–MT3.9 all passing.
- COUP-5 and NUTL-1's pass/fail thresholds reviewed by a person against real products (not just unit-tested), since these are the first features whose *correctness*, not just functionality, directly affects user trust.
- PRICE-9/NUTL-3/NUTL-4 logged as carried forward per the note above.

---

## Phase 4 — Full Nutrition Planning, Tracking, Cross-User Sharing & Compliance

**Scope reference:** [development-plan.md § Phase 4](development-plan.md#phase-4--full-nutrition-planning-tracking-cross-user-sharing--compliance-fully-integrated-system)

### Setup

- Equipment: EQ-D1, EQ-D2, EQ-D3, EQ-N2, EQ-A1.
- Two household test accounts (EQ-A1) each with at least one recipe created, for the sharing test cases.
- A real, publicly-reachable recipe URL with structured (schema.org) markup identified ahead of time for RECIPE-5's import test — this is the one test case in the whole plan that depends on the public internet rather than just the LAN/Hooper, since it's fetching a real third-party page.
- iOS build produced via EQ-D3 before starting the PLAT-2 regression pass.

### Requirements Tested

| ID | Requirement Gist | Verified By |
|---|---|---|
| PLAN-2 | Per-member biometric goals with trend | MT4.1 |
| PLAN-3 | Dated history of goal changes | MT4.2 |
| NPROC-1 | Server-side recipe/cooking computation | AT4.1 (indirectly), MT4.3 |
| RECIPE-1 | Create a recipe | MT4.3 |
| RECIPE-2 | Compute nutrients incl. calories | AT4.1 |
| RECIPE-3 | Link ingredient to branded product | MT4.3 (optional path) |
| RECIPE-4 | Flag ambiguous unit conversions | AT4.2 |
| RECIPE-5 | Import from structured-markup URL | MT4.3 |
| RECIPE-6 | Manual recipe entry fallback | AT4.2, MT4.3 |
| RECIPE-7 | Timestamped, member-attributed intake log | MT4.1-style check, re-run for intake |
| COOK-1 | Adjust nutrients for cooking method | AT4.3, MT4.4 |
| COOK-2 | Flag when no adjustment data available | AT4.3, MT4.4 |
| COOK-3 | Tag/confirm detected cooking method | AT4.3 |
| TRACK-1 | Manual biometric entry | MT4.1 |
| TRACK-2 | Every measurement recorded with source | AT4.4 |
| TRACK-3 | Data model ready for future tracker integration | Code review (schema inspection, not a runtime test) |
| TRACK-4 | Append-only history, corrections supersede | AT4.4 |
| TRACK-5 | Source-precedence rule | AT4.5 |
| TRACK-6 | Adherence vs. goal-version-at-the-time | AT4.6, MT4.2 |
| PRIV-1 | Health data logically separated | AT4.7 |
| PRIV-2 | Distinct opt-in for health data | AT4.7 |
| PRIV-3 | Export/delete health data | MT4.8 |
| PRIV-4 | Encryption + audit logging | AT4.7 (config check, not a full security audit) |
| PRIV-5 | Legal review gate | **Not a test case — see Exit Criteria** |
| PROV-1 | Export as FHIR bundle | MT4.9 |
| PROV-2 | Select categories/date range per share | MT4.9 |
| PROV-3 | Explicit per-instance consent | MT4.9 |
| SHAREGOV-1 | Shared-data classification checklist | Documentation review (not a runtime test) |
| RSHARE-1 | Private by default, explicit share | MT4.5 |
| RSHARE-2 | Attribution on shared recipes | MT4.5 |
| RSHARE-3 | Fork-on-save | AT4.8, MT4.5 |
| RSHARE-4 | Revisions as new linked version | MT4.6 |
| RSHARE-5 | Search/browse shared recipes | MT4.5 |
| RSHARE-6 | Report a shared recipe | MT4.7 |
| RCOPY-1 | Functional core only in shared representation | AT4.8 |
| RCOPY-2 | Contributor attestation before publishing | MT4.5 |
| RCOPY-3 | Notice-and-takedown process | MT4.7 |
| RCOPY-4 | Legal review gate | **Not a test case — see Exit Criteria** |
| PLAT-2 | Runs on iOS | MT4.10 |

### Automated Test Cases

| ID | Description | Type |
|---|---|---|
| AT4.1 | Recipe nutrient computation (RECIPE-2): known ingredient sets against expected totals, including calories, within a defined tolerance band. | Unit |
| AT4.2 | Unit-conversion ambiguity flagging (RECIPE-4) triggers correctly on genuinely ambiguous quantities; manual-entry fallback (RECIPE-6) works when import/computation isn't available. | Unit |
| AT4.3 | Cooking-method adjustment (COOK-1/COOK-2/COOK-3): one case with a matching cooked-state reference, one falling back to a retention-factor table, and one with neither — the third must show the "no adjustment available" flag, never a confident-looking wrong number. | Unit |
| AT4.4 | Append-only tracking history (TRACK-2/TRACK-4): every entry carries a source; a correction creates a new superseding record while the original remains queryable, not deleted. | Unit |
| AT4.5 | Source-precedence rule (TRACK-5) with synthetic manual + simulated-tracker entries on overlapping timestamps. | Unit |
| AT4.6 | Adherence evaluation (TRACK-6): computed against an older goal version after the current goal has since changed (using PLAN-3's history), and against the current version for a new entry. | Unit |
| AT4.7 | Health-category Firestore collections are access-scoped separately from shopping/pricing data (PRIV-1); a write to nutrition-plan data is rejected without a recorded opt-in (PRIV-2); encryption-at-rest and audit-logging configuration present (PRIV-4, config-level check). | Integration (rules + config) |
| AT4.8 | Sharing a recipe (RSHARE-3) produces an independent copy for the receiving household, not a live reference; the shared/canonical representation stores only the functional core (ingredients, steps), with narrative text/photos kept separate and attributed (RCOPY-1). | Integration (on-device + emulator) |

### Manual Test Cases

| ID | Steps | Expected Result |
|---|---|---|
| MT4.1 | Set up biometric goals (weight, blood pressure) with different trends for two household members; log manual measurements for both. | History views correctly attributed per member, no cross-contamination. |
| MT4.2 | Change a member's sodium target; inspect an intake log entry from before the change. | Old entry still evaluated against the old target; a new entry uses the new one. |
| MT4.3 | Create a recipe manually; separately, import a recipe from the real URL identified in Setup. | Both produce sensible computed nutrition; import correctly parses the structured markup. |
| MT4.4 | Enter the same recipe's steps twice, once tagged "boiled" and once "fried." Also include one step whose ingredient/method combination has no tabulated adjustment data. | Calories/fat differ in the expected direction between boiled/fried; the untabulated case shows the "no adjustment" flag rather than a wrong number. |
| MT4.5 | Share a recipe from household A (EQ-A1 account 1); search for and save it from household B (account 2); edit the saved copy in household B. | Sharing requires the contributor attestation (RCOPY-2); household A's original and household B's copy remain independent (RSHARE-3); attribution is visible on the shared listing. |
| MT4.6 | Publish a revised version of the same recipe from household A. | Household B's already-saved copy is unaffected; the new version is discoverable separately (RSHARE-4). |
| MT4.7 | Report a shared recipe. | It enters a reviewable moderation state (RSHARE-6/RCOPY-3). |
| MT4.8 | Export health data, then delete it. | A full, human-readable export is produced; after deletion, the data is actually gone, not just hidden from the UI. |
| MT4.9 | Generate a provider-sharing export, selecting a specific data category and date range. | Resulting bundle contains only what was selected; attempting a second share requires a fresh consent action. |
| MT4.10 | Re-run the Phase 1–3 manual test scripts (MT1.*, MT2.*, MT3.*) on the iOS build from EQ-D3. | No platform-specific regressions. |

### Exit Criteria

- AT4.1–AT4.8 and MT4.1–MT4.10 all passing on both Android and iOS.
- **PRIV-5 and RCOPY-4 are hard gates, tracked separately from test results, not test cases with a pass/fail run.** Provider-sharing (PROV-1/2/3) and public recipe sharing (RSHARE-1 and everything downstream of it) must not be enabled in any production or public-facing build until a documented legal counsel sign-off exists for each. Track this as its own checklist item outside the test-case list above.
- Any remaining Should Have / Nice to Have gap from any phase is documented as a known follow-up, since Phase 4 is the "fully integrated system" milestone the whole plan is measured against.

---

## Requirements Coverage Summary

Every requirement in `docs/requirements.md` maps to at least one test case above (or, for a handful of non-runtime items, to an explicit non-test verification method — code review, documentation review, or the legal-review gates). If a requirement is added or changed in `docs/requirements.md`, add or update its row in the relevant phase's "Requirements Tested" table in the same edit — this document should never fall out of sync with the requirements it claims to cover.
