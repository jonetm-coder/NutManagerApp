# ADR 0016: Recipe Creation, Import & Ingredient Nutrient Computation

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Users will create and import recipes, and the app must compute the nutrient values of all ingredients to determine a recipe's nutrition and, over time, track a household member's intake. Recipe ingredients are typically written generically ("1 cup flour," "2 chicken breasts") rather than referencing a specific scanned/branded product, which is a different resolution problem from the branded-product nutrition data established in ADR 0013. Recipes also need an import path, and their nutrient values may need adjustment for how they're cooked (ADR 0017).

## Decision

- **Recipe model**: a title, an ingredient list (each line: quantity, unit, and an ingredient reference), a servings/yield count, and a sequence of steps (free text, with an optional structured cooking-method tag per relevant step to feed ADR 0017).
- **Ingredient resolution**: match each ingredient line against a **generic-ingredient nutrient reference database** (e.g., USDA FoodData Central's Foundation/SR Legacy data) — distinct from the branded-product database used for in-store scanning (ADR 0013), since recipes are usually written generically. Allow a user to optionally link an ingredient to a specific branded product from the ADR 0013 database instead, when more precision is wanted.
- **Unit conversion**: maintain a standard unit-conversion table (volume/weight to grams, common recipe units) to scale per-100g reference nutrient data to the ingredient's specified quantity. Where conversion is inherently ambiguous (e.g., "1 cup chopped onion" depends on chop size), flag it for user confirmation/estimate rather than silently guessing a precise number.
- **Computation**: sum resolved, quantity-scaled, cooking-method-adjusted (ADR 0017) ingredient nutrients — including **calories (energy)**, which is computed and displayed the same as any other tracked nutrient rather than treated as a special case — divide by servings for a per-serving value, computed server-side per the processing split in ADR 0015.
- **Import**: support recipe import via **URL, parsing structured recipe markup** (schema.org Recipe/Recipe microdata, already embedded by most major recipe websites) as the primary import path, with manual entry as the universal fallback. Freeform/unstructured text or photo-based recipe import is explicitly deferred as a future enhancement.
- **Intake tracking**: each time a household member consumes a recipe serving (or a standalone logged food), record a timestamped, member-attributed intake log entry, feeding the tracking history in ADR 0019.

## Consequences

- Two distinct nutrient reference datasets now exist — generic ingredient data (this ADR) and branded product data (ADR 0013) — which must share a common nutrient identifier scheme so values from either source remain comparable/aggregable, even though they're sourced and maintained separately.
- Unit-conversion ambiguity is a genuine, unavoidable source of imprecision; surfacing that uncertainty in the UI rather than presenting a falsely precise number is a deliberate choice with real UX implications.
- URL-based structured import covers most major recipe sites at low cost but does nothing for a recipe shared as a text message, photo of a handwritten card, or a non-conforming site — an accepted initial gap given manual entry remains available.
- Server-side computation (per ADR 0015) means a recipe's nutrition isn't available until the next sync after creation/editing, which is acceptable under the "generally connected while planning" assumption.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Resolve recipe ingredients against the same branded-product database as in-store scanning** | Avoids maintaining two nutrient datasets | Recipes are rarely written in terms of specific brands, so match rates against a branded-product database would be poor |
| **Attempt full unstructured recipe text/photo import (OCR + NLP) from the start** | Broadest possible recipe-source coverage | Much larger, riskier scope than structured URL import + manual entry; better suited to a later enhancement once core plan/tracking features are proven |
| **Compute recipe nutrients client-side** | Available immediately after editing, even offline | Contradicts the server-side computation and centralized-dataset rationale established in ADR 0015 |
