# ADR 0024: Recipe Copyright & Contributor Liability

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

> **This ADR is not legal advice.** It records the engineering team's current, non-authoritative understanding and a recommended default posture, following the same approach as ADR 0020. Copyright and platform-liability exposure for user-generated recipe content should be confirmed with legal counsel (ideally with intellectual-property/UGC-platform experience) **before public recipe sharing (ADR 0023) launches**.

## Context

Once users can share recipes with the broader user base (ADR 0023), a real risk exists: a user could submit a recipe copied from a cookbook, food blog, or other copyrighted source rather than one they created themselves. By hosting and redistributing it, the app could face copyright infringement exposure as a hosting platform, could expose the submitting user to their own liability, and could damage trust with consuming users if content is later taken down.

US copyright law on recipes is genuinely nuanced, and this app's data model choices are not neutral with respect to that law: courts have generally held that a bare list of ingredients and simple, functional cooking instructions are **not copyrightable** on their own, since they're treated as facts/procedures rather than protected expression. However, the **literary expression** surrounding a recipe — narrative descriptions, personal anecdotes, distinctive phrasing, photographs, and video — **can** be protected by copyright. That distinction matters directly here because ADR 0023 already separates a recipe's functional core (ingredients, quantities, procedural steps) from any narrative/media content, which gives us a concrete lever to reduce exposure through the data model itself, not just through policy documents. General UGC-hosting tools also apply: the US DMCA's notice-and-takedown safe harbor (which requires a registered agent and a compliant process) can limit platform liability for user-submitted infringing content, and a Terms of Service can require contributors to represent that they have the right to share what they submit.

## Decision

- **Require legal counsel review before public recipe sharing (ADR 0023) launches.** This ADR records engineering's working understanding and a recommended default posture, not a legal conclusion, and should not be treated as a substitute for that review.
- **Minimize infringement surface through the data model**: consistent with the general understanding that a recipe's functional core (ingredient list with quantities, and concise numbered/procedural steps) is not copyrightable while narrative text and media can be, the *shared* recipe representation (ADR 0023) should store and prominently display primarily the functional core. Rich narrative text and photos/video remain optional, contributor-attributed content that the contributor affirms is their own original work — not something assumed safe to redistribute simply because it was submitted.
- **Require an explicit contributor representation at share time**: before a recipe is published to the global collection, require the contributing user to affirmatively confirm — via a clear, specific attestation, not text buried in a general Terms of Service — that they created the content or otherwise have the right to share it.
- **Establish a notice-and-takedown process**, modeled on the DMCA safe-harbor framework and finalized with legal counsel, so a rights holder can report a shared recipe as infringing and have it promptly reviewed and removed, and so repeat-infringing contributors can be addressed. This directly uses the reporting mechanism already planned in ADR 0023.
- **Do not treat "recipes aren't copyrightable" as a blanket shield.** That understanding applies only to the bare functional core, is fact-specific, and does not eliminate risk around accompanying text/photos or wholesale copying of an expressive presentation. The mitigations above — data-model restraint, contributor attestation, a takedown process, and legal review — are complementary, not substitutes for one another.

## Consequences

- Restricting the shared/canonical recipe representation to its functional core (per ADR 0023) reduces, but does not eliminate, copyright exposure, and shapes product UX: users can still add their own story or photos as clearly-attributed contributor content, but that content shouldn't be treated as automatically safe to feature or redistribute as broadly as the functional data.
- Contributor attestation and a takedown process are real engineering and process scope — a specific attestation flow, a reporting/moderation pipeline, and a designated process for handling legal notices — that must exist before public recipe sharing ships, not be added afterward.
- Deferring the precise legal risk assessment to counsel, rather than the engineering team assuming either "we're fine, recipes aren't copyrightable" or "this is too risky to ever do," avoids both overconfidence and unnecessary feature paralysis — but it does mean ADR 0023 should not launch publicly ahead of that review.
- This ADR should be revisited if the product later allows richer recipe media (e.g., user-submitted videos) or expands internationally, since copyright doctrine and UGC-hosting liability frameworks (DMCA is US-specific; other jurisdictions, e.g. the EU, have different regimes) vary by jurisdiction.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Allow full free-text/rich-media recipe sharing with no data-model restraint, relying only on takedown-after-the-fact** | Simpler product/data model; maximizes contributor expression | Materially higher infringement exposure, since takedown is reactive — infringing content stays live and redistributed until someone notices and reports it |
| **Prohibit recipe sharing entirely to avoid the issue** | Eliminates this specific risk | Abandons a feature with real user value; overly conservative given that standard, well-established mitigations exist for UGC platforms |
| **Attempt automated copyright-similarity detection against known cookbook/web sources before allowing a share** | Could proactively catch verbatim copying | Technically difficult and unreliable to build well, with real false-positive/negative risk; doesn't replace the need for data-model restraint, attestation, or a takedown process — could be considered later as a supplementary measure, not a substitute |
