# ADR 0002: Product Label Capture & Recognition Method

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

The app must identify a physical product from what the camera sees on a shelf or in-hand. Real-world grocery products present several distinct visual identification surfaces:

- A printed barcode (UPC-A/EAN-13 most commonly), present on nearly all packaged goods.
- Printed text (brand, product name, size) on the label, which may be needed when a barcode is missing, damaged, unreadable, or absent (e.g., loose produce, bulk bins, deli-counter items, in-store bakery items, handwritten price tags).
- The overall visual appearance of the packaging (color, logo, shape), which can be a fallback for produce and other unlabeled items.

This decision determines what capture/recognition pipeline stages ADR 0003 (on-device AI runtime) must support.

## Decision

Use a **hybrid, staged recognition pipeline**, attempted in this order for each scan:

1. **Barcode scan** (primary path): if a barcode is detected in frame, decode it and look up the UPC/EAN against the local product catalog cache (see ADR 0005). This is fast, cheap, and highly reliable when available.
2. **OCR fallback**: if no barcode is found within a short scan window, or the decoded barcode isn't in the local catalog, run on-device text recognition (OCR) on the label and extract brand/product name/size candidates for matching (see ADR 0004).
3. **Image classification fallback**: for items with no barcode and little/no legible text (e.g., loose produce), fall back to a lightweight on-device image classifier trained on a constrained category set (common produce/bulk items) to propose a category, with the user confirming or correcting the result.

Each stage degrades gracefully to the next rather than requiring the user to pick a mode manually.

## Consequences

- Requires maintaining three recognition code paths instead of one, increasing implementation and testing surface area.
- Barcode-first ordering keeps the common case fast and battery-efficient (barcode decoding is cheap relative to OCR or classification inference).
- The OCR and image-classification fallbacks require an on-device model/toolkit selection, which is addressed in ADR 0003.
- The image classifier's category set will initially be small and curated (common produce), with accuracy expected to be lower than barcode/OCR paths; the UI must clearly surface confidence and allow easy manual correction.
- Because all three stages must run fully offline, cloud-based vision APIs (e.g., Google Cloud Vision) are ruled out for this pipeline.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Barcode-only** | Simplest to implement; fast and accurate when available | Fails entirely for produce, bulk items, damaged/missing barcodes — a common real-world case for a grocery app |
| **OCR-only** | Handles both packaged and some unlabeled items via text | Slower and less reliable than barcode decoding for the majority (packaged) case; produce/bulk items often have no usable text |
| **Image classification only** | Handles unlabeled produce/bulk items directly | Requires large, continually-updated training data to cover the full grocery catalog; not practical to scale to branded packaged goods |
| **Cloud-based vision API (any stage)** | Higher accuracy, no on-device model maintenance | Violates the offline-in-store requirement; unacceptable latency/availability given spotty in-store connectivity |
