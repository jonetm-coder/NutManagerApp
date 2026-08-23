# ADR 0021: Healthcare Provider Data Sharing Interface

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

> This ADR describes a long-term interface design. See ADR 0020 for the privacy/compliance posture (business-associate obligations, safeguards, consent) that must be in place before any version of this interface ships.

## Context

Sharing a user's nutrition plan, goals, and tracked biometric history (ADR 0014, ADR 0019) with their healthcare provider is a planned long-term requirement, not just a hypothetical. A provider (or their EHR system) is a fundamentally different kind of consumer of this data than the household-member-facing app itself: providers generally expect data in **standardized, interoperable formats**, may want it inside their own clinical systems rather than as a one-off document, and the data flow itself carries the HIPAA business-associate implications discussed in ADR 0020. We don't control what EHR systems a given provider uses, so the interface needs to be realistic about what's achievable without per-provider custom integration work, while still being designed toward genuine interoperability rather than a dead-end proprietary format.

## Decision

- **Model shareable data as HL7 FHIR resources**, the dominant healthcare interoperability standard in the US (and increasingly elsewhere), rather than a proprietary export format: biometric measurements (weight, blood pressure, blood glucose) as FHIR `Observation` resources, nutrition/biometric targets (ADR 0014) as FHIR `Goal` resources, and logged intake (ADR 0016/0019) using FHIR's nutrition-related resources (e.g., `NutritionIntake`) or a documented extension where the standard doesn't yet have a precise fit. This keeps the data understandable to any system that already speaks FHIR, which most modern EHR platforms do to some degree (driven in part by US ONC interoperability requirements).
- **Start with a user-initiated export, not a live API integration.** The near-term achievable interface is a **FHIR Bundle** (a structured, machine-readable document containing the relevant resources) accompanied by a human-readable summary (e.g., a PDF), which the user can download, email, or upload to a provider's patient portal themselves. This avoids requiring cooperation, certification, or a live integration agreement with any specific EHR vendor before the feature can exist at all.
- **Design the underlying data models (ADR 0014, 0016, 0019) to be FHIR-mappable from the start**, even though the export path ships first — the same "design now, build later" approach already used for tracker integration (ADR 0018) — so that a future real-time integration (e.g., a **SMART on FHIR** OAuth2-based connection allowing a provider's system to pull authorized data directly, or to receive it via a push API) doesn't require reworking the core data model, only adding a new transport/authorization layer on top of it.
- **Scope every share to explicit, user-directed consent**: the user selects what to share (which data categories, and optionally a date range) and with whom (a named provider/portal, not a standing blanket connection), for each sharing event. There is no default "always shared with provider X" state; every export or connection is an affirmative, revocable action by the user.
- **Treat a live/API-based integration (SMART on FHIR or similar) as a distinct, later phase**, gated on the safeguards and business-associate posture from ADR 0020 being in place, real user/provider demand, and the practical realities of EHR vendor cooperation — this ADR commits to the direction and the FHIR-mappable data model now, not to building the live integration on any particular timeline.

## Consequences

- Building on FHIR from the start means the data model work here overlaps with, and should be coordinated alongside, ADR 0014/0016/0019 — nutrient and goal identifiers chosen there should be selected with an eye toward mapping cleanly onto FHIR resource fields, to avoid a translation layer that's lossy or awkward to maintain.
- Shipping export-first rather than live-integration-first gets a real, usable capability out much sooner (no EHR vendor dependency) at the cost of it being a manual, user-mediated step rather than seamless system-to-system sharing — an accepted tradeoff given we don't control EHR-side cooperation.
- Per-share, per-provider consent (rather than a standing connection) is more friction for the user on each occasion, but is a materially safer default for sensitive health data and aligns with the consent posture ADR 0020 establishes.
- Committing to FHIR (rather than a simpler custom format) is more upfront complexity than a plain data dump, but a custom format would need bespoke translation for every future provider integration and would face real adoption resistance, given how central FHIR already is to US healthcare interoperability expectations.
- Because the live-integration phase is explicitly deferred, this ADR carries the same risk noted in ADR 0018 for tracker integration: real-world SMART on FHIR implementation may surface requirements (specific EHR vendor quirks, certification requirements) this ADR didn't anticipate. The FHIR-mappable data model is a strong starting point, not a finished contract.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Build a live SMART on FHIR API integration from the start, skip the export-first phase** | Most seamless experience for providers if it works | Requires EHR vendor cooperation, app/security certification, and a live authorization flow — a heavy lift not justified before there's demonstrated user/provider demand; also blocks any provider-sharing capability until that integration is complete |
| **Use a proprietary/custom data format instead of FHIR** | Avoids the complexity of mapping our data model onto FHIR resources | FHIR is the dominant, largely expected standard in US healthcare interoperability (reinforced by ONC certification requirements on EHR vendors); a custom format would require bespoke translation work for every future provider integration and would likely face provider-side adoption resistance |
| **No structured export at all — user manually re-enters or screenshots data for their provider** | Zero engineering effort | Poor UX, error-prone, and defeats the purpose of the app having tracked structured data in the first place |
