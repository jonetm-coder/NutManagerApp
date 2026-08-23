# ADR 0019: Biometric & Intake Tracking History and Multi-Source Reconciliation

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Over time, a household member accumulates a time series of biometric measurements (manual today, tracker-sourced later per ADR 0018) and nutrient-intake log entries (from consumed recipes/logged foods, per ADR 0016). This history needs to support trend viewing and adherence reporting, must handle multiple sources reporting the same metric on overlapping timestamps (e.g., a manual weight entry and a smart-scale sync on the same day), and must handle corrections to a past entry without corrupting the historical record.

## Decision

- Store all biometric measurements and nutrient-intake log entries as an **append-only time-series log** per household member per metric/nutrient. A correction to a past entry creates a new record that supersedes/references the original rather than overwriting it in place, preserving full history for audit and accurate trend analysis.
- When multiple sources report the same metric for overlapping timestamps, apply a **source-precedence rule** rather than averaging or picking arbitrarily: a tracker-synced value (once ADR 0018 integrations exist) takes precedence for display over a manual entry covering the same window, on the assumption an automated measurement is generally more precise/consistent — but the manual entry is retained and viewable, not deleted, since the user may have deliberately logged a specific reading a device didn't capture.
- Compute trend/adherence views (e.g., "did this week's average sodium intake fall within goal") against the **goal version that was active at the time** of each historical entry, per ADR 0014's plan versioning — not the member's current goals — so historical adherence reporting doesn't silently change when goals are later updated.
- Store this tracking history under the cloud-first posture established in ADR 0015, with the manual-entry offline outbox fallback noted there for occasional connectivity gaps.

## Consequences

- Append-only history with superseding corrections adds modest storage/complexity relative to overwrite-in-place, but is necessary for trustworthy trend reporting and for evaluating past entries against the goals active at the time.
- The tracker-over-manual source-precedence rule is a reasonable default, not a settled fact; it should be revisited once real tracker integrations (ADR 0018) exist and actual data-quality patterns are observed, and should be implemented as a documented, adjustable rule rather than a hardcoded assumption.
- Computing adherence against the goal version active at the time creates a dependency on ADR 0014's goal-versioning model; the two should be implemented together, with goal versioning in place first.
- An append-only, multi-source model requires a somewhat more capable query/aggregation layer (e.g., "give me the effective value for weight on date X, accounting for precedence") than a naive single-row-per-day table — this should be designed for from the outset rather than retrofitted later.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Overwrite in place for corrections, no history of superseded values** | Simpler storage model | Loses the audit trail and can distort trend analysis if a correction changes an outlier that was already part of a computed average |
| **Average multiple same-day sources instead of a precedence rule** | Doesn't discard any single source's contribution | Produces a blended number that may not correspond to any real single measurement, and obscures which source is more trustworthy |
| **Always evaluate historical entries against current goals rather than goals active at the time** | Simpler, single-goal lookup | Misrepresents past adherence retroactively whenever goals change — e.g., making past behavior look like a failure against a stricter goal adopted later |
