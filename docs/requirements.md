# Requirements

This document derives functional requirements for NutManagerApp from the architectural decisions recorded in [docs/adrs/](adrs/). Each requirement is traceable to the ADR(s) it was derived from.

## Priority Definitions

- **Must Have**: The core product will not be acceptable without this functionality.
- **Should Have**: Important functionality but will not block product release if it turns out to be too difficult/time consuming to implement.
- **Nice To Have**: Not a core requirement for the product but a nice usability enhancement.

Acceptance criteria are left blank where not yet known; they should be filled in as the relevant feature is designed in detail.

## Platform & Client Support

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| PLAT-1 | The app shall run on Android devices. | Must Have | | ADR 0001 |
| PLAT-2 | The app shall run on iOS devices. | Should Have | | ADR 0001 |
| PLAT-3 | The app shall provide camera-based scanning as a core input method on all supported platforms. | Must Have | | ADR 0001, ADR 0002 |

## Product Scanning & Identification

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| SCAN-1 | The app shall identify a product by scanning its printed barcode. | Must Have | Given a product with an undamaged, standard barcode (UPC-A/EAN-13), scanning it resolves to a specific product without requiring network connectivity. | ADR 0002, ADR 0003 |
| SCAN-2 | The app shall identify a product via on-device text recognition (OCR) of its label when no barcode is present, unreadable, or not found in the local catalog. | Must Have | | ADR 0002, ADR 0003 |
| SCAN-3 | The app shall identify a product's category via on-device image classification when it has no usable barcode or legible text (e.g., loose produce). | Should Have | | ADR 0002, ADR 0003 |
| SCAN-4 | All product identification (barcode, OCR, image classification) shall function with no network connectivity. | Must Have | Given the device in airplane mode, scanning a product previously present in the locally cached catalog successfully identifies it. | ADR 0002, ADR 0003, ADR 0005 |
| SCAN-5 | The app shall distinguish barcodes in globally-assigned ranges from store-local (Restricted Circulation Number) ranges, and shall not treat a store-local barcode as a global product match. | Must Have | | ADR 0012 |
| SCAN-6 | The app shall correctly parse variable-weight/price-embedded barcodes (e.g., meat, deli, produce) so that the stable product identity is recognized independent of the encoded weight/price. | Must Have | Given two packages of the same variable-weight product with different embedded weights, both scans resolve to the same product identity. | ADR 0012 |
| SCAN-7 | When product identification confidence is low or ambiguous, the app shall prompt the user to confirm or correct the result rather than silently accepting it. | Must Have | | ADR 0002, ADR 0004 |
| SCAN-8 | The app shall allow a user to manually identify/correct a product when automatic identification fails or is wrong. | Must Have | | ADR 0002, ADR 0008 (pattern) |
| SCAN-9 | The app shall allow users to contribute new or corrected barcode-to-product mappings to a shared database. | Should Have | | ADR 0012 |
| SCAN-10 | The barcode-to-product database shall be seeded from existing open data sources rather than built from zero. | Should Have | | ADR 0012 |

## Shopping List Management

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| LIST-1 | The app shall download the user's current household shopping list from the cloud prior to a shopping trip. | Must Have | | ADR 0005, ADR 0006 |
| LIST-2 | The app shall match an identified/scanned product to a corresponding item on the active shopping list. | Must Have | | ADR 0004 |
| LIST-3 | The app shall prompt the user to confirm a match when multiple shopping list items score similarly or no match exceeds the confidence threshold. | Must Have | | ADR 0004 |
| LIST-4 | The app shall allow the user to remove a previously scanned/added item from their shopping basket. | Must Have | Given an item has been added to the basket (via scan or manual add), the user can select it and remove it; the item no longer appears in the basket and, if it originated from the shopping list, returns to an unfulfilled state on the list. | *(derived; not explicit in existing ADRs — consider documenting in a future ADR/UI spec)* |
| LIST-5 | The app shall allow manual addition of a shopping list item that scanning does not resolve. | Should Have | | ADR 0004 (implied) |
| LIST-6 | The app shall maintain a category/synonym mapping used to bridge differences in wording between scanned products and shopping list text. | Should Have | | ADR 0004 |
| LIST-7 | Multiple members of the same household shall be able to view and edit a shared shopping list. | Must Have | | ADR 0006, ADR 0007 |

## Offline Operation & Sync

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| SYNC-1 | The app shall cache the active shopping list and a relevant subset of the product catalog locally before a shopping trip. | Must Have | | ADR 0005 |
| SYNC-2 | The app shall queue changes made while offline (items marked found/purchased, new scan-to-product matches, manual list additions) and apply them to the cloud once connectivity is restored. | Must Have | | ADR 0005 |
| SYNC-3 | No core in-store action (viewing the list, marking/removing an item, scanning a product) shall be blocked by lack of network connectivity. | Must Have | Given airplane mode is enabled, the user can view the shopping list, scan and match products, and add/remove basket items without error. | ADR 0005 |
| SYNC-4 | The system shall resolve conflicting concurrent edits to the same list/item from multiple household devices without data loss beyond an accepted last-write-wins rule. | Should Have | | ADR 0005 |

## Cloud Storage & Household Sharing

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| CLOUD-1 | The cloud backend shall store nutritional information, recipes, and shopping lists per household. | Must Have | | ADR 0006 |
| CLOUD-2 | The system shall restrict a household's private data (shopping lists, recipes, coupons) to authorized members of that household only. | Must Have | | ADR 0006, ADR 0007 |
| CLOUD-3 | The system shall perform server-side computation (e.g., nutrition rollups, recipe recommendations) without relying on client-submitted derived data as trusted input. | Should Have | | ADR 0007 |
| CLOUD-4 | Client access to cloud data shall go through an app-internal abstraction layer so the backend can be replaced without rewriting business logic. | Should Have | | ADR 0007 |

## Pricing Capture & Comparison

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| PRICE-1 | The app shall allow the user to capture a product's price by scanning a printed shelf tag. | Must Have | | ADR 0008 |
| PRICE-2 | The app shall allow manual price entry when a price cannot be reliably read (e.g., handwritten/hand-marked labels). | Must Have | | ADR 0008 |
| PRICE-3 | The app shall record each captured price together with the product, the store, and a timestamp. | Must Have | | ADR 0008, ADR 0010 |
| PRICE-4 | The app shall allow the user to compare a product's price across nearby stores. | Should Have | | ADR 0010 |
| PRICE-5 | The app shall allow the user to configure the geographic radius or set of stores used for price comparison. | Nice to Have | | ADR 0010 |
| PRICE-6 | When offline, the app shall display the most recently synced price comparison data along with a visible last-updated timestamp rather than blocking the feature. | Should Have | | ADR 0005, ADR 0010 |
| PRICE-7 | The system shall maintain a shared, cross-household historical pricing dataset without attaching personally identifying information to contributed price observations. | Must Have | | ADR 0011 |
| PRICE-8 | The app shall allow a user to opt out of contributing their own scanned price data to the shared dataset, without losing the ability to view shared price history. | Must Have | | ADR 0011 |
| PRICE-9 | The system shall apply basic validation (e.g., outlier detection) to submitted price data before it is shown to other users. | Should Have | | ADR 0011 |

## Coupons

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| COUP-1 | The app shall allow the user to capture a printed coupon by scanning its barcode. | Must Have | | ADR 0009 |
| COUP-2 | The app shall allow manual entry of an electronic/digital coupon's details. | Should Have | | ADR 0009 |
| COUP-3 | The app shall match an applicable coupon to a scanned product, accounting for expiration date, minimum purchase quantity, and size/variant exclusions. | Must Have | | ADR 0009 |
| COUP-4 | The app shall surface an applicable coupon to the user for confirmation rather than automatically applying it. | Must Have | | ADR 0009 |
| COUP-5 | The app shall warn the user when a scanned product is in the same category as, but does not match, a product for which the user holds a coupon. | Should Have | Given a coupon on file for product A in category C, when the user scans product B in category C that does not satisfy the coupon, the app displays a non-blocking warning identifying the coupon and product A, without auto-substituting or auto-applying anything. | ADR 0009 |
| COUP-6 | Coupons shall be stored as household-private data and synced across the household's devices. | Must Have | | ADR 0006, ADR 0009 |

## Barcode Database

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| BC-1 | The system shall maintain a barcode-to-product mapping database covering both globally-assigned and store-scoped (Restricted Circulation Number) barcode ranges. | Must Have | | ADR 0012 |
| BC-2 | The system shall keep store-scoped barcode mappings isolated per store and never surface them as a match at a different store. | Must Have | | ADR 0012 |
| BC-3 | The system shall support crowdsourced correction of barcode mappings, with mitigation against erroneous or bad-faith submissions (e.g., requiring multi-contributor corroboration). | Should Have | | ADR 0012 |
| BC-4 | A relevant subset of the barcode database shall be synced to the device for offline lookup. | Must Have | | ADR 0005, ADR 0012 |

## Nutrition Label Reading & In-Store Goal Matching

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| NUTL-1 | The app shall indicate whether a scanned product's nutrition fits each household member's nutrition goals, in real time, while offline. | Must Have | Given household member goals and a product's nutrition data are cached locally, scanning the product displays a per-member pass/fail or warning indicator without requiring network connectivity. | ADR 0013, ADR 0014 |
| NUTL-2 | The app shall read a product's Nutrition Facts panel via on-device OCR when nutrition data for that product is not already available in the local/cloud catalog. | Must Have | | ADR 0013 |
| NUTL-3 | The app shall allow users to contribute newly-captured or corrected nutrition data back to a shared nutrition database. | Should Have | | ADR 0013 |
| NUTL-4 | The system shall apply a higher validation/corroboration bar to crowdsourced nutrition data corrections than to pricing or barcode corrections. | Should Have | | ADR 0013 |

## Nutrition Plan & Biometric Goals

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| PLAN-1 | Each household member shall be able to define personal nutrient targets (e.g., calories, carbohydrates, fatty acids, protein, fiber, sodium, sugar, vitamins, minerals), each as a minimum-only, maximum-only, or range. | Must Have | | ADR 0014 |
| PLAN-2 | Each household member shall be able to define personal biometric goals (e.g., weight, blood pressure, blood sugar) with a target value/range and a desired trend. | Must Have | | ADR 0014 |
| PLAN-3 | The system shall retain a dated history of changes to a member's nutrient targets and biometric goals rather than overwriting prior values. | Must Have | | ADR 0014 |
| PLAN-4 | Nutrition plans and biometric goals shall be stored as household-private data, scoped per household member. | Must Have | | ADR 0014, ADR 0006, ADR 0007 |
| NPROC-1 | Recipe and cooking-method nutrient computation shall be performed server-side; a recipe's computed nutrition shall become available after the next sync following creation/editing. | Should Have | Given a recipe is created or edited while offline, its nutrient values are not shown until connectivity is restored and a sync completes. | ADR 0015 |
| NPROC-2 | The app shall maintain a read-only local snapshot of each household member's currently active goals so in-store goal matching (NUTL-1) works offline, without requiring general offline editing of plans, recipes, or history. | Must Have | | ADR 0015 |

## Recipe Creation, Import & Nutrient Computation

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| RECIPE-1 | The user shall be able to create a recipe consisting of a title, an ingredient list (quantity, unit, ingredient), a servings count, and steps. | Must Have | | ADR 0016 |
| RECIPE-2 | The system shall compute a recipe's nutrient values, including calories, by resolving each ingredient against a generic-ingredient nutrient reference database and scaling by quantity. | Must Have | | ADR 0016 |
| RECIPE-3 | The user shall be able to link a recipe ingredient to a specific branded product for more precise nutrient computation. | Nice to Have | | ADR 0016 |
| RECIPE-4 | The app shall flag ingredient quantities with ambiguous unit conversion for user confirmation rather than silently estimating. | Should Have | | ADR 0016 |
| RECIPE-5 | The user shall be able to import a recipe from a URL that provides structured recipe markup. | Should Have | | ADR 0016 |
| RECIPE-6 | The user shall be able to manually create/enter a recipe as a fallback when import is unavailable or fails. | Must Have | | ADR 0016 |
| RECIPE-7 | The app shall record a timestamped, member-attributed intake log entry each time a household member consumes a logged recipe serving or food. | Must Have | | ADR 0016 |

## Cooking Method Effects

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| COOK-1 | The system shall adjust a recipe's computed nutrient values (including calories) for the cooking method applied to relevant ingredients, using published cooked-state data or retention-factor tables where available. | Should Have | | ADR 0017 |
| COOK-2 | When no cooking-method adjustment data is available for an ingredient/method combination, the app shall display the unadjusted value with a visible indication that no adjustment was applied. | Must Have | | ADR 0017 |
| COOK-3 | The app shall tag recipe steps with a detected cooking method from a curated set (raw, boiled, steamed, baked/roasted, fried, grilled, microwaved) and allow the user to confirm or correct it. | Should Have | | ADR 0017 |

## Health & Fitness Tracking

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| TRACK-1 | The user shall be able to manually enter biometric measurements (weight, blood pressure, blood sugar, etc.) for themselves and other household members. | Must Have | | ADR 0018 |
| TRACK-2 | Every biometric measurement shall be recorded with a source (e.g., manual, or a specific tracker integration), even before any tracker integration exists. | Must Have | | ADR 0018 |
| TRACK-3 | The measurement data model shall accommodate a future tracker-sourced entry using the same shape as a manual entry, without a breaking schema change, when integration with a platform health aggregator (e.g., HealthKit, Health Connect) is added. | Should Have | | ADR 0018 |
| TRACK-4 | Biometric measurements and nutrient-intake log entries shall be retained as an append-only history; a correction to a past entry shall supersede rather than overwrite it. | Must Have | | ADR 0019 |
| TRACK-5 | When multiple sources report the same metric for overlapping timestamps, the system shall apply a defined source-precedence rule (tracker over manual) for display while retaining all submitted values. | Should Have | | ADR 0019 |
| TRACK-6 | Adherence/trend reporting shall evaluate each historical entry against the goal version active at the time it was logged, not the member's current goals. | Must Have | | ADR 0019, ADR 0014 |

## Health Data Privacy & Provider Sharing

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| PRIV-1 | Health-category data (nutrition plans, biometric goals/measurements) shall be logically separated from non-health app data (shopping lists, pricing, coupons) in storage and access control. | Must Have | | ADR 0020 |
| PRIV-2 | The system shall require a distinct, explicit user opt-in before collecting any nutrition-plan or biometric data, separate from consent for other app data. | Must Have | | ADR 0020 |
| PRIV-3 | The user shall be able to export or delete their health-category data. | Must Have | | ADR 0020 |
| PRIV-4 | All health-category data shall be encrypted in transit and at rest, with access audit logging distinct from general app logging. | Must Have | | ADR 0020 |
| PRIV-5 | The legal classification of health data handling (HIPAA and other applicable regimes) shall be confirmed with legal counsel before any healthcare-provider-facing feature ships to production. | Must Have | A documented legal review sign-off exists prior to enabling provider data sharing (PROV-1/2/3) in production. | ADR 0020 |
| PROV-1 | The user shall be able to export their nutrition plan, goals, and biometric history as a structured, standardized data bundle (FHIR-based) suitable for sharing with a healthcare provider. | Should Have | | ADR 0021 |
| PROV-2 | The user shall be able to select which data categories and date range to include in a given provider share, rather than sharing all data by default. | Must Have | | ADR 0021 |
| PROV-3 | Each provider data share shall require an explicit, per-instance user consent action; there shall be no standing default-on connection to a provider. | Must Have | | ADR 0021 |

## Cross-User Data Sharing Governance

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| SHAREGOV-1 | Every cross-user shared data type shall be classified as household-private, geo/store-scoped, or global, with a documented attribution model, contribution-consent model, and abuse-mitigation approach. | Must Have | | ADR 0022 |

## Recipe Sharing & Discovery

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| RSHARE-1 | Recipes shall be private by default; sharing a recipe to the global collection shall be an explicit, per-recipe user action. | Must Have | | ADR 0023 |
| RSHARE-2 | A shared recipe shall display its contributor's attribution, or "anonymous" if the contributor opts out. | Must Have | | ADR 0023 |
| RSHARE-3 | When a household saves a shared recipe, they shall receive their own editable copy rather than a live reference to the original. | Must Have | | ADR 0023 |
| RSHARE-4 | A later revision to a shared recipe shall publish as a new linked version rather than mutating what other households have already saved. | Should Have | | ADR 0023 |
| RSHARE-5 | The user shall be able to search/browse the global recipe collection by name, ingredient, or dietary tag. | Should Have | | ADR 0023 |
| RSHARE-6 | The user shall be able to report a shared recipe (e.g., inappropriate content, suspected copyright issue). | Must Have | | ADR 0023 |

## Recipe Copyright & Contributor Liability

| ID | Requirement | Priority | Acceptance Criteria | Source |
|---|---|---|---|---|
| RCOPY-1 | The shared/canonical representation of a recipe shall store and prominently display primarily its functional core (ingredients with quantities, concise numbered steps); narrative text and photos/video shall be optional, separately-attributed contributor content. | Must Have | | ADR 0024 |
| RCOPY-2 | Before a recipe is published to the global collection, the contributing user shall be required to explicitly affirm that they created it or otherwise have the right to share it. | Must Have | | ADR 0024 |
| RCOPY-3 | The system shall provide a notice-and-takedown process allowing a rights holder to report a shared recipe as infringing and have it reviewed/removed. | Must Have | | ADR 0024 |
| RCOPY-4 | Legal counsel review of the recipe-sharing copyright/liability approach shall be completed before public recipe sharing (RSHARE-1) launches in production. | Must Have | A documented legal review sign-off exists prior to enabling public recipe sharing in production. | ADR 0024 |

## Requirements Not Yet Covered by an ADR

- **LIST-4** (remove a scanned/basket item) was identified during requirements derivation and is not yet documented in any ADR. It is low-risk enough not to need one, but if its implementation raises a nontrivial design question (e.g., how removal interacts with the offline outbox queue in ADR 0005, or whether a removed item's coupon/price associations are also cleared), consider writing a short ADR at that point.
