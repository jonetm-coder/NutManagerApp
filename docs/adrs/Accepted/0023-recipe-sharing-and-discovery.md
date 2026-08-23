# ADR 0023: Recipe Sharing & Discovery

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Recipes created or imported by a household (ADR 0016) start as household-private data. Unlike a shopping list or pricing observation, a recipe's usefulness doesn't depend on the creating household's location or circumstances, so it makes sense to let users share recipes with the broader user base per the **global** sharing scope defined in ADR 0022. This requires deciding: what state a recipe is in by default, what sharing actually does to the recipe record, how another household then uses a shared recipe, how edits/versions are handled, how shared recipes are discovered, and how the app responds to problem content (quality, appropriateness, or the copyright question addressed separately in ADR 0024).

## Decision

- Per ADR 0022, recipe sharing is **global-scope, attributed** sharing: a shared recipe displays its original contributor (or "anonymous," if the contributor opts out of attribution at share time).
- Recipes remain **private by default**, per ADR 0016's household-owned model. Sharing is an explicit, per-recipe, user-initiated action — never automatic.
- Sharing a recipe **publishes an immutable, versioned snapshot** into a separate global recipe collection, distinct from the sharer's private copy. This prevents a confusing situation where another household's saved recipe silently changes or disappears because the original author later edited or deleted their private copy. If the author shares a revised version later, it publishes as a new version linked to the previous one (mirroring the plan-versioning approach in ADR 0014), rather than mutating what other households already have.
- A household that finds a shared recipe gets their **own private, editable copy** ("save"/"fork") when they add it to their collection — not a live reference to the original. This keeps per-household edits (portion size, ingredient substitutions) from affecting the shared original or any other household, and keeps nutrient computation (ADR 0016) simply scoped to the copy that household actually owns.
- Provide basic **discovery** (search/browse by name, ingredient, or dietary tag) over the global recipe collection, and a **lightweight reporting mechanism** on shared recipes (inappropriate content, suspected copyright issue — feeding into ADR 0024's process) rather than building a full social/recommendation platform at this stage.

## Consequences

- Fork/copy-on-save semantics avoid a class of confusing bugs and bad UX where one household's edits or account deletion silently changes what another household sees, at the cost that a saved recipe won't automatically pick up the original author's later improvements — a household has to notice and re-save a newer version manually.
- Immutable published snapshots plus versioning add modest data-model complexity beyond the base recipe model in ADR 0016, but are necessary to avoid "the recipe I saved changed under me."
- Choosing attribution (rather than the anonymous model used for pricing/barcode data, ADR 0011/0012) fits recipes specifically — contributors typically want credit — and supports the copyright/liability handling in ADR 0024, since an attributed submission creates a clear record of who shared what.
- A reporting/moderation mechanism becomes required infrastructure once recipes are public user-generated content, which is new engineering and process scope beyond anything the shopping or pricing features needed.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Live reference instead of fork-on-save** (consumers always see the latest version automatically) | Simpler mental model in some respects; always up to date | A shared recipe silently changing or disappearing out from under a household's meal plan is a worse experience, and complicates cached nutrient computation |
| **Anonymous recipe sharing, no attribution**, consistent with ADR 0011's pricing model | Simpler, reuses an existing pattern | Undesirable for recipes specifically — contributors typically want credit, and attribution supports the copyright/liability handling needed in ADR 0024 |
| **No moderation/reporting mechanism at launch** | Less initial engineering scope | Leaves no path to respond to inappropriate or infringing shared content — an unacceptable gap once recipes are public, especially given the copyright question in ADR 0024 |
