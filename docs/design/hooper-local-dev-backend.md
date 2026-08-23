# Hooper: Temporary Local Development Backend

**Status:** Interim/temporary setup, not an architectural decision. This document describes the current dev/test environment and how it's expected to be retired once the real cloud backend is stood up. It doesn't change or supersede [ADR 0006 (Cloud Backend Platform)](../adrs/Accepted/0006-cloud-backend-platform.md) — Firebase remains the target production backend; this is just where and how it's being stood in for during early development.

## Purpose

Standing up a real Firebase project this early isn't necessary — most early development and functional testing doesn't need production infrastructure, billing exposure, or public reachability. Instead, the backend ("the web side" — the cloud services the mobile app talks to, per ADR 0006/0007) is being stood up locally on **Hooper**, a Raspberry Pi already on the home network, for the current development phase.

## Hardware & Host

- **Hooper** is a Raspberry Pi 4 or 5 running a 64-bit OS.
- This is genuinely modest hardware compared to any real cloud infrastructure. It's expected to be *sufficient for single-developer functional testing* — it is explicitly **not** representative of production performance, and shouldn't be used to draw any conclusions about how the real backend will perform once it's on actual cloud infrastructure.

## Why Run This in a VM

Rather than installing the backend stand-in directly on Hooper's host OS:

- **Isolation** from anything else Hooper is used for.
- **Snapshot/rollback** while the emulator setup is still being figured out — cheap to reset to a known-good state instead of debugging host-level drift.
- **Resource capping** — the VM can be given a fixed CPU/RAM allocation so it can't starve whatever else Hooper is doing.
- **Hardware-assisted virtualization (KVM) is viable** on a Pi 4/5 with a 64-bit kernel, which keeps virtualization overhead reasonable on hardware this modest. (This would not be a reasonable plan on a Pi 3 or a 32-bit OS, where KVM support is poor to nonexistent — noting this in case Hooper is ever swapped for older hardware.)

The specific hypervisor/tooling (e.g., libvirt + QEMU/KVM) is an implementation detail to be filled in as it's set up; this document will be updated once that's settled.

## What Runs Inside the VM: Firebase Local Emulator Suite

The VM runs Google's official [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite), emulating Firestore, Auth, Cloud Functions, and Cloud Storage locally — the same four Firebase products ADR 0006 chose for the real backend.

This matters for how clean the eventual transition is: the mobile app talks to the **same Firebase client SDK APIs** whether it's pointed at the local emulator or the real cloud project. There's no separate "local backend API" to build or throw away — dev builds just configure the Firebase SDK to connect to Hooper's emulator endpoints instead of a live project.

## Network Reachability & Testing Implications

- Hooper is reachable only on the **local home network** — there's no port-forwarding or VPN set up to reach it from outside, and none is planned for this interim setup.
- This means "online" during this development phase effectively means "on the same LAN as Hooper." That's a fine stand-in for functional testing (does the sync logic work, does a Firestore write show up, etc.), but it is **not representative of real-world connectivity** — it has none of the latency, intermittency, or availability characteristics of an actual cellular/store-Wi-Fi connection or a real cloud endpoint.
- This particularly affects testing the assumptions in [ADR 0005](../adrs/Accepted/0005-offline-local-storage-and-sync.md) (offline-first in-store shopping) and [ADR 0015](../adrs/Accepted/0015-cloud-local-split-nutrition-planning.md) (cloud-first nutrition planning, which assumes general connectivity) — both can be functionally tested against Hooper, but genuine field testing (an actual shopping trip, testing behavior on real spotty store Wi-Fi) needs either a temporary tunnel back to Hooper or, more likely, waiting until the real cloud backend exists.

## Known Limitations

Being upfront about what this setup is *not*:

- **Single point of failure**, no uptime guarantees, no automated backups beyond whatever the developer does manually.
- **Limited concurrency/performance headroom** — a Pi running a VM running the emulator suite (the Firestore emulator alone runs on a JVM) has a low ceiling. Fine for one developer clicking through the app; not a substitute for any real load or performance testing.
- **Not security-hardened for exposure beyond a trusted home LAN.** Hooper's emulator ports should never be exposed to the public internet as configured for this purpose.
- **Emulator behavior can subtly diverge from production** — quota/rate-limit behavior, and occasionally newer API surface, may not be perfectly emulated. Don't treat "works against the emulator" as a guarantee it'll behave identically against the real service.

## Transition Plan to Real Cloud Infrastructure

**Trigger conditions** (any of these means it's time to move off Hooper):

- Ready for real in-store field testing beyond the home LAN.
- More than one developer/tester needs concurrent access to a shared backend.
- Need to validate behavior against real Firebase quotas, billing, or performance characteristics.
- Approaching a releasable prototype milestone.

**Steps:**

1. Create a real Firebase project (consider whether separate dev/staging vs. production Firebase projects are wanted — that's a decision for its own discussion when this becomes relevant, not decided here).
2. Deploy the existing Firestore security rules, indexes, and Cloud Functions from version-controlled source to the real project. These should already be tracked as source alongside the app (not just clicked together in the local emulator UI), so this step is a deploy, not a rebuild.
3. Repoint the mobile app's build configuration (e.g., Flutter build flavors / environment-specific Firebase config files) from Hooper's local emulator endpoints to the live Firebase project.
4. Re-run the functional test suite against the live project before relying on it for anything real.
5. Decommission or repurpose Hooper as the dev backend once it's no longer needed for that role (it can still be useful for other things — this just retires its role as the backend stand-in).

## Open Questions

- Whether dev/staging/production Firebase project separation eventually warrants its own ADR — not decided here; this document only describes the current interim local setup.
- Exact VM hypervisor/tooling choice on Hooper — to be filled in once set up.
