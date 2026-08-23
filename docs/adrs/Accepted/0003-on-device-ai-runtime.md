# ADR 0003: On-Device AI Runtime

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

ADR 0002 requires three on-device capabilities, all of which must run fully offline with acceptable latency and battery impact on a phone:

1. Barcode detection/decoding.
2. Text recognition (OCR) on product labels.
3. A custom, lightweight image classifier for barcode-less/text-less items (e.g., produce).

The client is Flutter (ADR 0001), so the chosen runtime(s) must have solid Flutter interop (either an official/community plugin or a straightforward platform-channel bridge), and must work on both Android and iOS without diverging model formats per platform if avoidable.

## Decision

Use a **two-runtime split**:

- **Google ML Kit** (via `google_mlkit_barcode_scanning` and `google_mlkit_text_recognition` Flutter plugins) for barcode decoding and OCR. ML Kit ships production-grade, pre-trained, on-device models for both tasks on Android and iOS, requires no custom training, and has first-party Flutter plugin support.
- **TensorFlow Lite** (via `tflite_flutter`) for the custom image classifier (produce/bulk-item fallback) and for the product-matching embedding model referenced in ADR 0004. TFLite has mature Flutter tooling, runs on both platforms from a single `.tflite` model file, supports quantization for smaller/faster models, and integrates with hardware acceleration (NNAPI on Android, Core ML delegate on iOS) where available.

## Consequences

- Barcode/OCR quality and maintenance are delegated to Google, reducing our training/maintenance burden for those two tasks; we take on a dependency on Google Play Services on Android (ML Kit's on-device models are bundled/downloaded via Play Services) and the separate ML Kit iOS SDK.
- We retain full control and a single cross-platform model format (TFLite) for the parts of the pipeline that are unique to this app (produce classification, product-matching embeddings), which is where our own training data and iteration matter most.
- App size grows from bundling the TFLite model(s); model updates require either an app release or a separate model-download mechanism (out of scope for this ADR).
- Two different runtimes/toolchains must be tested and monitored for platform compatibility regressions (e.g., a Play Services or iOS SDK update).
- If ML Kit's on-device availability or licensing terms change unfavorably, the barcode/OCR stages would need to migrate to an alternative (e.g., a TFLite-based OCR model), which is a non-trivial rework.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Single custom pipeline on ONNX Runtime Mobile** | One runtime for everything; full control over all models; avoids Google Play Services dependency | Must train/maintain our own barcode and OCR models from scratch — significant effort to match ML Kit's out-of-the-box accuracy |
| **Core ML (iOS) + separate Android runtime** | Best possible performance/battery on iOS via native Apple silicon optimization | Not cross-platform — requires maintaining entirely separate models/pipelines per OS, undermining the Flutter single-codebase goal |
| **PyTorch Mobile** | Familiar training workflow if team already uses PyTorch | Weaker Flutter plugin ecosystem than TFLite; larger runtime footprint; less mobile-optimized tooling (quantization, delegates) than TFLite |
| **Cloud-based inference for OCR/classification** | Simpler on-device footprint, easier model updates | Violates the offline-in-store requirement established in ADR 0002 |
