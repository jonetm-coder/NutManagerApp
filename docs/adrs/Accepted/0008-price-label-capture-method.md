# ADR 0008: Price Label Capture Method

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

Comparing and tracking prices (see ADR 0010, ADR 0011) requires capturing the price of a product at the point of scanning, in addition to identifying the product itself (ADR 0002). In-store prices are shown via two distinct surfaces:

- **Printed shelf tags**: machine-printed labels on the shelf edge, often with a structured layout (product name, price, unit price, sometimes a barcode/UPC of their own).
- **Hand-marked labels**: stickers or grease-pencil/marker prices on produce, bakery, deli, or clearance items — unconstrained placement and often handwritten, which is significantly harder to OCR reliably than printed text.

This must work fully offline, consistent with the rest of the capture pipeline (ADR 0002), and reuse the on-device OCR runtime already chosen (ADR 0003) rather than introduce a new one.

## Decision

Treat price capture as a **user-initiated secondary scan step**, distinct from (but chained after) product identification, rather than attempting fully automatic detection of a price tag's location relative to the product in one frame:

1. After a product is identified (barcode/OCR/classification, per ADR 0002), the app prompts the user to optionally scan the nearby price tag/sticker.
2. Run the same on-device OCR (ML Kit text recognition, per ADR 0003) against the captured price-tag image, applying a price-specific parser (currency symbol/decimal pattern matching) to extract a numeric price and, where present, a unit price.
3. If OCR confidence is low or the label is handwritten/illegible, fall back to **manual price entry** by the user rather than guessing.
4. Store the resulting price observation locally (tied to the product, the current store — see ADR 0010 — and a timestamp), queued for sync per the offline-first model in ADR 0005.

## Consequences

- Reuses the existing OCR runtime and offline pipeline rather than introducing a new capture technology, keeping engineering scope contained.
- A two-step scan (product, then price) is a small extra user action per item, but is far more reliable than attempting automatic multi-object detection (locating a price tag on a shelf relative to a held product) in a single frame — a materially harder computer-vision problem not justified at the prototype stage.
- Handwritten/hand-marked prices will have meaningfully lower OCR accuracy than printed shelf tags; the manual-entry fallback is a required part of this decision, not an edge case.
- Price data quality (and therefore the usefulness of ADR 0010/0011) depends on users actually performing this optional second scan; the UX must make it low-friction (e.g., a single tap immediately after product capture) to encourage consistent use.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Fully automatic price-tag detection in the same frame as the product** | No extra user action; potentially faster end-to-end scan | Substantially harder vision problem (localizing an unrelated object in a cluttered shelf scene); not justified given team size/prototype stage |
| **Manual price entry only (no OCR)** | Simplest to implement; works for any label type including handwriting | Slower for the common case of printed shelf tags, where OCR works well; discourages consistent price capture due to friction |
| **Rely on the shelf tag's own barcode only (if present) to look up price from a store database** | Avoids OCR entirely when a shelf-tag barcode exists | Not all shelf tags have a barcode; no store-provided price database is assumed to exist/be accessible offline; doesn't handle hand-marked prices at all |
