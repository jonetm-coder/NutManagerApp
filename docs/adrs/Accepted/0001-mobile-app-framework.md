# ADR 0001: Mobile App Framework

- **Status:** Accepted
- **Date:** 2026-08-23
- **Author(s):** jonetm@gmail.com

## Context

NutManagerApp's client is a mobile app that must:

- Ship an Android prototype first, with an iOS release planned afterward.
- Access the camera for real-time product label scanning.
- Run on-device AI inference (barcode/OCR/classification) with low latency, since network connectivity in-store is expected to be spotty or absent.
- Maintain a local offline data store and sync with a cloud backend.
- Be built and maintained by a small team, favoring development velocity and a single codebase over squeezing out maximum native performance.

We need to choose the client framework/language before further platform-specific ADRs (on-device AI runtime, local storage) can be finalized, since it constrains which SDKs and plugins are available.

## Decision

Use **Flutter** (Dart) as the cross-platform mobile framework for both the Android prototype and the future iOS release.

Rationale:

- Single codebase for Android and iOS satisfies the stated cross-platform goal without maintaining two parallel native apps.
- Mature camera (`camera`), barcode/OCR (`google_mlkit_*`), and on-device inference (`tflite_flutter`, `onnxruntime`) plugins exist for Flutter, covering the needs of later ADRs.
- Dart's platform channels and FFI allow dropping into native code (Kotlin/Swift/C++) for performance-critical or platform-exclusive AI APIs (e.g., Core ML) if a plugin gap is found later.
- Strong hot-reload/dev-loop speed suits rapid prototyping of the Android-first MVP.

## Consequences

- The team commits to Dart, which has a smaller talent pool and library ecosystem than JavaScript or Kotlin/Swift.
- Bleeding-edge platform ML APIs (e.g., new Core ML or NNAPI features) may lag behind in Flutter plugins and require writing custom platform channel bridges.
- App binary size is larger than an equivalent native app due to the Flutter engine, compounded further by bundled ML models.
- UI is rendered by Flutter's own engine rather than native widgets; this is generally acceptable for this app's largely custom UI (scanner overlay, lists) but is a minor risk for perfect platform look-and-feel conformance.
- Because the client language is Dart, the on-device AI runtime (ADR 0003) must be chosen from options with solid Flutter interop.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **React Native** | Large ecosystem, JS talent pool | Bridge overhead is a poor fit for real-time camera/ML frame processing; ML plugin ecosystem less mature than Flutter's for this use case |
| **Kotlin Multiplatform (KMP) + native UI** | Share business logic, fully native UI and best access to platform ML APIs (ML Kit, Core ML) per-platform | Still requires writing two UIs (Compose + SwiftUI); more total engineering effort; less mature tooling than Flutter for a small team |
| **Fully native (Kotlin + Swift, two codebases)** | Best possible performance and first-class access to every platform ML API | Doubles UI and business-logic development/maintenance cost; slowest path to an iOS release; not justified for the prototype stage |
