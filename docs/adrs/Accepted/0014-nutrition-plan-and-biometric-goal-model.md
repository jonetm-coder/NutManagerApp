# ADR 0014: Nutrition Plan & Biometric Goal Data Model

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Each household member should be able to create and maintain a personal nutrition plan consisting of:

- **Nutrient targets**: bounds on nutrients such as **calories (energy)**, carbohydrates, fatty acids (saturated, unsaturated, trans), protein, fiber, sodium, sugar, vitamins, and minerals. Some nutrients naturally have only a minimum (e.g., protein, fiber), some only a maximum (e.g., sodium, added sugar, trans fat), and some a full range (calorie targets, for instance, are commonly set as a range or a maximum depending on the member's goal). Calories are expected to be one of the most commonly set targets and often the one most directly linked to a weight goal (see biometric goals below), so they must be a first-class nutrient in this model, not an afterthought.
- **Biometric goals**: targets for measured health outcomes such as weight, blood pressure, and blood sugar. These are fundamentally different from nutrient targets — they are physiological measurements tracked over time (manually today, via health trackers later per ADR 0018), not values computed from food, and are often about a *direction of change* (e.g., "trending down") as much as a fixed threshold.

ADR 0013 already defined a simpler per-household-member, per-serving nutrient goal profile used for real-time in-store product matching. This ADR generalizes that into the full nutrition plan, which becomes the authoritative source; the in-store check in ADR 0013 should be understood as a narrow, real-time projection of the richer model defined here, not a separate goal system.

## Decision

- Model a **nutrient target** as: a nutrient identifier drawn from a standardized reference list (aligned to USDA/FDA nutrient IDs so it interoperates with the product and recipe nutrient data in ADR 0013/0016), a bound type (**minimum-only**, **maximum-only**, or **range**), the bound value(s) and unit, and a time basis that defaults to **per day** (matching how most dietary guidance — RDAs, Daily Values — is expressed), while remaining available as a per-serving value for the in-store real-time check in ADR 0013.
- Model a **biometric goal** as a structurally distinct entity: a metric identifier (weight, systolic/diastolic blood pressure, blood glucose, etc.), a target value or range, and a desired **trend** (decreasing, maintaining, increasing) — since biometric goals are frequently about trajectory over time rather than a single instantaneous pass/fail threshold.
- Both nutrient targets and biometric goals are owned **per household member**, not per household, consistent with the requirement that each family member has personal goals, and are stored as household-private data (ADR 0006/0007).
- **Version the plan over time**: changes to a member's nutrient targets or biometric goals are recorded as dated entries rather than overwritten in place, so that later adherence/trend analysis (ADR 0019) can evaluate a historical entry against the goals that were actually active when it was logged.

## Consequences

- This becomes the single authoritative nutrient-goal model; ADR 0013's in-store per-serving check should read from a projection of it rather than maintaining an independently-defined goal shape, avoiding two divergent sources of truth.
- Supporting minimum-only/maximum-only/range per nutrient avoids forcing a meaningless fabricated bound (e.g., an invented "minimum sodium") on nutrients the user only cares about in one direction.
- Treating biometric goals as a distinct, trend-oriented entity type (rather than reusing the nutrient-target shape) means two goal models must be built and presented in the UI instead of one, but avoids awkwardly cramming weight/blood-pressure goals into a per-serving-evaluable shape that doesn't fit them.
- A calorie nutrient target and a weight biometric goal are related but distinct (e.g., a calorie range supports a weight-trend goal) and should be presented so a user understands the connection, without collapsing them into a single entity — the UI/UX for goal-setting should make that relationship clear rather than leaving the user to infer it.
- Versioning goals adds modest data-model complexity (a history of goal states, not just current values) but is required for any adherence reporting to remain meaningful when goals change — "did I meet my goal" is undefined without knowing what the goal was at the time.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **A single generic "target range" type for both nutrients and biometrics** | Simpler, one model to build | Forces trend-oriented biometric goals into a min/max shape that doesn't naturally fit them, and forces fabricated bounds where a nutrient is only bounded on one side |
| **No goal versioning — overwrite in place when goals change** | Simpler storage | Corrupts historical adherence analysis retroactively whenever a goal is updated |
| **Household-level goals instead of per-member** | Simpler data model and UI | Directly contradicts the stated requirement that each family member has their own goals |
