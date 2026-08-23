# Architectural Decision Records (ADRs)

This folder tracks architectural decisions for NutManagerApp using lightweight ADRs.

## Folders

- `Proposed/` — new ADRs under discussion, not yet decided
- `Accepted/` — ADRs the team has agreed to follow
- `Rejected/` — ADRs that were considered and declined (kept for history/context)

## Workflow

1. Copy `template.md` into `Proposed/` and name it `NNNN-short-title.md`, where `NNNN` is the next zero-padded sequence number (e.g. `0001-use-postgres.md`).
2. Fill in Context, Decision, Consequences, and Alternatives Considered.
3. When a decision is made, move the file into `Accepted/` or `Rejected/` and update its `Status` field to match. Do not renumber it.
4. As part of accepting an ADR (i.e. when moving it into `Accepted/`), derive any new/changed requirements from it and add or update them in [../requirements.md](../requirements.md), noting the ADR as the source. Requirements should not be added for an ADR while it is still in `Proposed/`.
5. If a later decision supersedes an accepted ADR, leave the old one in place and note the superseding ADR's number in it; add a new ADR rather than editing history.

## Numbering

Sequence numbers are shared across all three folders (i.e. a single incrementing counter), so each ADR keeps a unique, stable ID regardless of which folder it currently lives in.
