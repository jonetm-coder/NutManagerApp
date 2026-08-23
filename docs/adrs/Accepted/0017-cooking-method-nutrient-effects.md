# ADR 0017: Cooking Method Effects on Nutritional Value

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Cooking measurably changes a food's nutrient content relative to its raw/as-purchased state: water-soluble vitamins (e.g., vitamin C, B vitamins) can leach out or degrade with heat and water exposure, especially boiling; fat content — and with it, **calorie (energy) content** — can increase (frying, oil absorption) or decrease (grilling, fat rendering off); moisture loss (roasting, grilling) concentrates some nutrients, including calories, per unit weight even while other nutrients degrade. Calories are one of the more visibly affected values here (e.g., frying can substantially raise a food's effective calorie count versus its raw or steamed equivalent), so getting the calorie adjustment reasonably right matters as much as any other nutrient this ADR covers. Recipe nutrient computation (ADR 0016) should account for this rather than reporting raw-ingredient values for a cooked dish, but precisely modeling the underlying chemistry (time, temperature, surface area, water volume, specific oil absorption) is not practical for a general-purpose app. This is expected to be one of the harder problems in the system, and the goal here is a workable, honestly-labeled approximation rather than a definitive solution.

## Decision

- Prefer **published cooked-state nutrient data** as the primary source when it exists: reference databases such as USDA FoodData Central often already publish separate entries for a food in specific prepared states (e.g., "raw" vs. "boiled" vs. "roasted"). When a recipe step's ingredient-and-method combination matches such an entry, use it directly rather than deriving an adjustment ourselves.
- Where no directly matching cooked-state entry exists, apply **published nutrient retention factor tables** (e.g., USDA's Table of Nutrient Retention Factors, which give a percentage retention per nutrient for a food category and cooking method) as multipliers against the raw value, rather than attempting first-principles chemical modeling.
- Where **neither** a matching cooked entry nor an applicable retention factor exists for a given ingredient/method combination, fall back to the **raw/as-labeled value** and clearly flag in the UI that no cooking adjustment could be applied for that ingredient — never present an unadjusted number as if it were precise.
- Scope automatic cooking-method detection to a **small, curated set of common methods** (raw, boiled, steamed, baked/roasted, fried, grilled, microwaved), tagged from free-text recipe steps (ADR 0016) via simple keyword matching, with the user able to confirm or correct the detected method per step rather than requiring perfect automatic detection.
- Treat this feature's output as an **explicitly-labeled estimate**, not a lab-grade value, wherever it's surfaced (recipe nutrition display, goal matching per ADR 0014).

## Consequences

- Relying on existing published data (cooked-state entries and retention-factor tables) avoids the infeasible task of modeling cooking chemistry directly, at the cost that accuracy is bounded by those tables' coverage and granularity, which is not exhaustive across every ingredient/method combination.
- The explicit "no adjustment available" fallback and UI flag matters for trust: silently returning a raw-value number for a food that was actually fried, with no indication, would be more misleading than a visibly labeled estimate or gap.
- Keyword-based cooking-method detection from recipe text will be imperfect and needs user confirmation as a normal part of the flow, not an edge case, given how widely natural-language recipe phrasing varies.
- This ADR should be treated as an ongoing accuracy area rather than a finished solution; retention-factor coverage and detection quality should be expected to improve iteratively rather than being solved once.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Ignore cooking method entirely; always use raw/as-purchased values** | Simplest possible implementation | Produces systematically wrong nutrient values for foods commonly eaten cooked, undermining trust in the whole tracking feature |
| **First-principles chemical/physical modeling of nutrient degradation** | Most accurate in theory | Requires food-science expertise and validation far beyond what's practical for this app; not attempted |
| **Crowdsource user-submitted "cooked nutrient value" corrections**, mirroring ADR 0011/0012 | Could improve coverage over time via community contribution | Nutrient content isn't something an ordinary user can measure or verify the way a price or barcode can; published reference tables are more trustworthy than ad hoc submissions for this specific kind of data |
