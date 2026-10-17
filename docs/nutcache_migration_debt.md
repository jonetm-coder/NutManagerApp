# NutCache Migration Debt

This document tracks deliberate decisions to build something locally, on the phone, even though the accepted architecture (an ADR) calls for it to be built or maintained centrally via NutCache. Each one is a conscious stopgap to make early progress without waiting on cloud infrastructure that doesn't exist yet — not a silent deviation from the ADR it departs from.

This is a running ledger, not a design document. The reasoning behind each decision lives in the code or ADR it came from. This file tracks what was done instead, why that's acceptable for now, and what moving it to NutCache will require.

## How to Use This Document

- **Add an entry whenever a development decision builds something locally/client-side that an accepted ADR envisions as centralized/cloud-side.** Add it in the same change that introduces the decision, not afterwards.
- **Give each entry a stable `MIGRATE-#` ID.** Never renumber or reuse IDs. When an item is migrated, mark it **Done**, note how and where it was verified, and leave it in place.
- **Link the entry to its source** (ADR, code) and to any requirements it affects.
- **Before this subsystem goes live with real users, every entry must be Done or explicitly accepted as not applicable**, with a reason — the same discipline as [securing_nuts.md](securing_nuts.md), just for architecture debt rather than security debt.

Entry format:

> ### MIGRATE-# — Short title
> - **Status:** Open | Done (date, how verified) | Not applicable (reason)
> - **Source:** where the decision was made (ADR, code)
> - **Dev decision:** what we're doing now
> - **Why it's acceptable for now:** the reasoning, and what the cost/risk of leaving it this way is
> - **Required to migrate:** concrete, checkable actions to move this to NutCache
> - **Related requirements:** IDs from [requirements.md](requirements.md), if any

---

## Entries

### MIGRATE-1 — External product lookups (Open Food Facts/UPCitemdb) happen directly from the phone

- **Status:** Open
- **Source:** ADR 0012 (Barcode Matching Database); implemented in `app/lib/services/product_lookup_service.dart`
- **Dev decision:** `ProductLookupService` calls Open Food Facts (primary) and UPCitemdb (secondary, best-effort) directly from the phone over the internet — both for "Check Products" (searching by name to pre-populate the catalog before a trip) and for scan-to-add's by-barcode lookup when a scanned product isn't already known locally or in this household's history. ADR 0012 designed the shared barcode database to be built and maintained centrally via NutCache (bootstrapped from sources like these, then crowdsourced from there), not queried live, per-device, by every household independently.
- **Why it's acceptable for now:** NutCache doesn't exist yet as a running backend a phone can call (Phase 1 is local-only, per `docs/development-plan.md`). Querying these open databases directly from the phone is the only way to get this functionality at all before that exists, and it's explicitly scoped as an interim measure, not the intended end state. The cost of leaving it this way: every household re-queries the same products instead of benefiting from what other households already resolved, there's no server-side caching/rate-limit pooling (UPCitemdb's free trial tier is rate-limited per caller), and no crowdsourced corroboration (BC-3) is possible on purely client-side results.
- **Required to migrate:**
  - Move both lookup paths (by-name search, by-barcode lookup) behind a NutCache Cloud Function that calls Open Food Facts/UPCitemdb server-side, caches results, and merges them into the shared barcode database (ADR 0012, SCAN-10).
  - `ProductLookupService` on the phone becomes a thin client of that function instead of calling the external APIs directly; `product_resolution_service.dart`'s external tier and `shopping_list_screen.dart`'s "Check Products" action both redirect to it with no change to their own logic.
  - Decide whether the by-barcode tier should even survive client-side once the shared barcode database (BC-4) syncs a relevant local subset — it may collapse into tier 1 (local catalog) entirely.
  - Remove the `INTERNET` Android permission's justification tied to this specific use once it's gone (re-check whether anything else still needs it before removing the permission itself).
- **Related requirements:** PLOOKUP-1, PLOOKUP-2, SCAN-10, BC-3, BC-4

---

## Migration Checklist

Before this subsystem is considered aligned with its target architecture:

- [ ] Every entry above is **Done** or **Not applicable** with a recorded reason.
- [ ] This document has been reviewed as a whole for gaps no single decision surfaced.
