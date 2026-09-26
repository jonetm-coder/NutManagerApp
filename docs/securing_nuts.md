# Securing NUTS: Go-Live Security Debt

*Securing NUTS* covers the security of the entire NutManager infrastructure: the app, NutCache, and everything they run on. In short, making sure no other squirrels steal our nuts. See the naming conventions in the [README](../README.md#naming-conventions).

During development we knowingly make security shortcuts that are fine for a private dev environment but not for a live system. For example, the NutCache dev instance relies entirely on the Tailscale tailnet for access control. This document records every such decision **at the time it's made**, together with what must happen to secure the system before it goes live. Nothing is meant to be forgotten between now and launch.

This is a running ledger, not a design document. The reasoning behind each decision lives in the ADR or design note it came from. This file tracks the security consequence and the go-live obligation.

## How to Use This Document

- **Add an entry whenever a development decision relies on a protection that won't exist, or won't be sufficient, in production.** Examples: relying on the VPN, test-only credentials, disabled checks, cleartext exceptions, broad permissions, and "we'll add auth later". Add it in the same change that introduces the decision, not afterwards.
- **Give each entry a stable `SEC-#` ID.** Never renumber or reuse IDs. When an item is resolved, mark it **Done**, note how and where it was verified, and leave it in place.
- **Link the entry to its source** (ADR, design note, or code) and to any requirements it affects (e.g. CLOUD-2, PRIV-4).
- **Before go-live, every entry must be Done or explicitly accepted as not applicable**, with a reason. This is a gate in the transition plan in [nutcache-dev-instance.md](design/nutcache-dev-instance.md#transition-plan-to-real-cloud-infrastructure).

Entry format:

> ### SEC-# — Short title
> - **Status:** Open | Done (date, how verified) | Not applicable (reason)
> - **Source:** where the decision was made
> - **Dev decision:** what we're doing now
> - **Why it's acceptable in development:** the compensating control, and what the risk is
> - **Required before go-live:** concrete, checkable actions
> - **Related requirements:** IDs from [requirements.md](requirements.md), if any

---

## Entries

### SEC-1 — Tailnet membership is the only access control on NutCache dev

- **Status:** Open
- **Source:** [nutcache-dev-instance.md § Network](design/nutcache-dev-instance.md#network-tailnet-only-access)
- **Dev decision:** The Firebase emulators have no real authentication. Firestore and Storage accept an `Authorization: Bearer owner` header that skips security rules. The Auth emulator issues unsigned tokens for any user, and the Hub and Auth expose unauthenticated export and delete-all endpoints. Access is limited only by the Tailscale tailnet and its policy (`tag:nutcache`).
- **Why it's acceptable in development:** The tailnet contains only the owner's devices. Tailscale's WireGuard tunnel encrypts traffic and authenticates each device. The data is test data only (SEC-4).
- **Required before go-live:**
  - Production NutCache runs on real Firebase, where no emulator-style bypass exists. Confirm no client or build flavor can point at emulator endpoints.
  - Security rules become the actual access boundary for Firestore and Storage. Run the rules test suite (AT2.5) against the deployed rules; CLOUD-2 is not met by client behavior alone.
  - Enable Firebase App Check so only genuine app builds can call Firestore, Storage, and Functions.
  - Configure real Firebase Auth. That means choosing sign-in providers, email verification, password policy, and whether MFA is required or offered.
- **Related requirements:** CLOUD-2, CLOUD-3

### SEC-2 — Plain HTTP to NutCache dev, with an Android cleartext exception

- **Status:** Open
- **Source:** [nutcache-dev-instance.md § Why Plain HTTP Rather Than HTTPS](design/nutcache-dev-instance.md#why-plain-http-rather-than-https)
- **Dev decision:** The app talks to the emulators over plain HTTP, because the Auth, Functions, and Storage SDKs only support `http://` in emulator mode. Debug builds carry an Android network security config exception allowing cleartext traffic to `nutcache.tail37f114.ts.net`.
- **Why it's acceptable in development:** Traffic is encrypted and device-authenticated inside WireGuard. The exception covers one hostname in debug builds only.
- **Required before go-live:**
  - Release builds must contain no cleartext exception. Add an automated check (build or CI step) that fails if the release network security config permits cleartext traffic, or if `usesCleartextTraffic` is enabled.
  - All production traffic goes over HTTPS to Firebase's own endpoints; there are no custom hosts.
  - The same check applies to iOS once it exists: no App Transport Security exceptions in release builds.
- **Related requirements:** PRIV-4 (encryption in transit)

### SEC-3 — Emulator admin surfaces are open to any tailnet device

- **Status:** Open
- **Source:** [nutcache-dev-instance.md § Ports Served on `nutcache`](design/nutcache-dev-instance.md#ports-served-on-nutcache)
- **Dev decision:** Any tailnet device can use the Emulator Suite UI (port 4000) and Hub (port 4400) to view, edit, export, or delete all data.
- **Why it's acceptable in development:** It's the same boundary as SEC-1: the owner's devices only, holding test data only.
- **Required before go-live:**
  - Admin access to production goes only through the Firebase and Google Cloud consoles. Access is controlled by Google Cloud IAM with least-privilege roles, and MFA is required on every account with project access.
  - Decide and document who holds Owner and Editor roles. There should be no shared accounts.
  - Enable Cloud Audit Logs for admin and data access. For health data, access logging must be distinct from general logging (PRIV-4).
- **Related requirements:** PRIV-4

### SEC-4 — Test data only; no real personal or health data in NutCache dev

- **Status:** Open
- **Source:** [nutcache-dev-instance.md § What Tailnet Access Implies](design/nutcache-dev-instance.md#what-tailnet-access-implies)
- **Dev decision:** NutCache dev holds synthetic test data only. It has none of the privacy controls required for real personal or health data.
- **Why it's acceptable in development:** There is no real user data to protect. This entry exists so that real data doesn't creep in during testing, e.g. the developer's own biometric data during Phase 4.
- **Required before go-live:**
  - Complete the health-data classification and legal review (PRIV-5, ADR 0020) before any real health data is stored.
  - Put the PRIV-4 controls in place for health-category data: encryption in transit and at rest, and access audit logging.
  - Confirm that data retention, deletion (user-initiated account and data deletion), and export are implemented for production.
- **Related requirements:** PRIV-4, PRIV-5, PROV-3

### SEC-5 — Cloud Functions run with admin privileges

- **Status:** Open
- **Source:** [nutcache-dev-instance.md § Ports Served on `nutcache`](design/nutcache-dev-instance.md#ports-served-on-nutcache)
- **Dev decision:** In the emulator, Functions run with full admin rights and are not subject to security rules. No per-function permission scoping is done.
- **Why it's acceptable in development:** It's the emulator's default, the data is test data only, and it's reachable only from the tailnet.
- **Required before go-live:**
  - Run each production function under a least-privilege service account, not the default one with broad access.
  - Validate all input in callable and HTTP functions. Callable functions must check `context.auth` and household membership themselves, because Functions bypass security rules.
  - Keep secrets such as API keys in Secret Manager, never in source or environment config committed to the repo.
- **Related requirements:** CLOUD-2, CLOUD-3

### SEC-6 — No quotas, rate limits, or billing protection

- **Status:** Open
- **Source:** [nutcache-dev-instance.md § Known Limitations](design/nutcache-dev-instance.md#known-limitations)
- **Dev decision:** The emulators enforce no quotas or rate limits, and there's no billing exposure.
- **Why it's acceptable in development:** The instance is local and has no public exposure.
- **Required before go-live:**
  - Set budget alerts on the Firebase/Google Cloud billing account.
  - Use App Check (see SEC-1) and set per-user or per-function limits where abuse could run up cost. Crowdsourced submissions such as prices and barcode corrections need abuse limits anyway (BC-3).
  - Review Firestore rules for unbounded queries or writes a malicious client could trigger.
- **Related requirements:** BC-3

### SEC-7 — Dev data and credentials on Hooper must be cleaned up at decommission

- **Status:** Open
- **Source:** [nutcache-dev-instance.md § Storage](design/nutcache-dev-instance.md#storage)
- **Dev decision:** The NutCache dev VM disk (`/mnt/netstorage/nutcache/`), emulator data exports (`/mnt/backup/nutcache/`), and the VM's Tailscale identity all live on Hooper. They sit on the LUKS-encrypted external drive.
- **Why it's acceptable in development:** The data is test data only, on an encrypted drive on the owner's hardware.
- **Required before go-live (or when NutCache dev is retired):**
  - Remove the `nutcache` device from the tailnet, and remove `tag:nutcache` from the tailnet policy.
  - Revoke any unused Tailscale auth keys created for it.
  - Delete the VM, its disk image, and its backups once they're no longer needed.
  - Confirm that no dev-only configuration (emulator hosts, the `demo-nutcache` project ID, test accounts) ships in release builds.

---

## Go-Live Checklist

Before NutCache handles real users or real data:

- [ ] Every entry above is **Done** or **Not applicable** with a recorded reason.
- [ ] This document has been reviewed as a whole, not just entry by entry, for gaps that no single decision surfaced.
