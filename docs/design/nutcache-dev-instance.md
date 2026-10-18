# NutCache Dev Instance on Hooper (Temporary Local Development Backend)

**Status:** Interim/temporary setup, not an architectural decision. This document describes the current dev/test environment and how it's expected to be retired once the real cloud backend is stood up. It doesn't change or supersede [ADR 0006 (Cloud Backend Platform)](../adrs/Accepted/0006-cloud-backend-platform.md) — Firebase remains the target production backend; this is just where and how it's being stood in for during early development.

## Naming

**NutCache** is the name of the server side of the application — the cloud services the mobile app talks to, per ADR 0006/0007. It names the service regardless of where it runs: this document describes the *NutCache dev instance*, a local stand-in hosted on Hooper; the real Firebase-hosted backend will also be NutCache.

| Thing | Name |
|---|---|
| Physical host | `hooper` (Raspberry Pi; keeps its own name and its other roles) |
| libvirt VM running NutCache dev | `nutcache` |
| Tailnet device / hostname | `nutcache` → `nutcache.tail37f114.ts.net` |
| Firebase project ID used by the emulators | `demo-nutcache` |
| VM disk image and host-side files | `/mnt/netstorage/nutcache/` |
| Backups of emulator data | `/mnt/backup/nutcache/` |
| Future real Firebase projects | e.g. `nutcache-dev`, `nutcache-prod` (see Open Questions) |

The `demo-` prefix on the project ID is deliberate: Firebase treats any project ID starting with `demo-` as emulator-only, so the SDKs and emulators refuse to reach real Google services with it. A misconfigured dev build can't accidentally talk to (or bill) a real project.

## Purpose

Standing up a real Firebase project this early isn't necessary — most early development and functional testing doesn't need production infrastructure, billing exposure, or public reachability. Instead, the NutCache dev instance is stood up on **Hooper**, a Raspberry Pi already on the home network, for the current development phase.

## Hardware & Host

- **Hooper** is a Raspberry Pi 4 Model B with 8 GB RAM, 4 cores, running 64-bit Debian 12 (bookworm).
- Hooper already runs other services (Docker containers including Vaultwarden/Caddy, Samba, and others). NutCache must not starve them — hence the VM's hard resource caps below.
- This is genuinely modest hardware compared to any real cloud infrastructure. It's expected to be *sufficient for single-developer functional testing* — it is explicitly **not** representative of production performance, and shouldn't be used to draw any conclusions about how the real backend will perform once it's on actual cloud infrastructure.

## Why Run This in a VM

Rather than installing the backend stand-in directly on Hooper's host OS:

- **Isolation** from anything else Hooper is used for.
- **Snapshot/rollback** while the emulator setup is still being figured out — cheap to reset to a known-good state instead of debugging host-level drift.
- **Resource capping** — the VM is given a fixed CPU/RAM allocation so it can't starve whatever else Hooper is doing.
- **Own network identity** — the VM joins the tailnet as its own device, so its ports never collide with Hooper's (Hooper already uses 5000 and 5001, the latter being the Functions emulator's default port).
- **Hardware-assisted virtualization (KVM) is viable** on a Pi 4/5 with a 64-bit kernel (confirmed working on Hooper), which keeps virtualization overhead reasonable on hardware this modest. (This would not be a reasonable plan on a Pi 3 or a 32-bit OS, where KVM support is poor to nonexistent — noting this in case Hooper is ever swapped for older hardware.)

### VM Specification

| Item | Value |
|---|---|
| Hypervisor/tooling | libvirt 9.0 + QEMU 7.2 with KVM (Debian 12 packages), UEFI boot (AAVMF) |
| Guest OS | Debian 12 (arm64) official `genericcloud` image, checksum-verified against Debian's `SHA512SUMS` |
| vCPUs | 2 (of Hooper's 4), `host-passthrough` CPU model |
| RAM | 3 GB. Hooper has only ~100 MB of swap, so this cap is what protects Hooper's other services from the OOM killer. Inside the VM, the Firestore emulator's JVM heap is capped by Java's default (1/4 of RAM, ~750 MB); no explicit `-Xmx` is set. **Caveat:** Hooper's kernel has the memory cgroup controller disabled (the Raspberry Pi default), so libvirt can't additionally cap QEMU's own overhead (~100-200 MB on top of guest RAM). Guest RAM itself can't exceed 3 GB regardless. Enabling the controller would mean editing the kernel command line that also carries the root-drive unlock settings; deliberately not done. |
| Disk | 32 GB thin-provisioned `qcow2` (keeps snapshots available) at `/mnt/netstorage/nutcache/nutcache.qcow2` |
| Network | libvirt `default` NAT network (`192.168.122.0/24`), with a DHCP reservation pinning the VM to `192.168.122.10`. The virtio NIC's option ROM is disabled (`<rom enabled='no'/>`): QEMU on arm64 otherwise fails looking for an x86 iPXE ROM the guest never uses. |
| Admin access | SSH from Hooper only: `ssh nutcache` (alias in Hooper's `~/.ssh/config`) as user `tjones`, key `~/.ssh/id_nutcache`. Password login disabled; the account has passwordless sudo (see SEC-7 in [securing_nuts.md](../securing_nuts.md)). |
| First-boot setup | cloud-init from a NoCloud seed ISO (`/mnt/netstorage/nutcache/user-data`, `meta-data`, `seed.iso`), then **disabled** (`/etc/cloud/cloud-init.disabled`). Without that, cloud-init treats each later boot as a new instance once the seed is ejected: it regenerates SSH host keys, creates a default `debian` user, and stalls boot ~5 minutes probing cloud metadata services. |
| Guest software | Java 21 (Eclipse Temurin; required by `firebase-tools`, and Debian 12 only ships 17), Node.js 22 LTS (NodeSource; a supported Cloud Functions runtime), `firebase-tools` pinned to an exact version, Tailscale, `qemu-guest-agent`. Installed by [`nutcache/dev-instance/provision-vm.sh`](../../nutcache/dev-instance/provision-vm.sh). |
| Emulators run as | `nutcache-emulators.service` inside the VM, as the unprivileged `nutcache` user, started at boot. About 20 s to ready on a restart, and about 1¾ minutes after a cold VM boot. See [`nutcache/README.md`](../../nutcache/README.md). |

## Build Status

| Step | Status |
|---|---|
| Hooper full OS upgrade (prerequisite) | Done 2026-10-18 |
| libvirt + QEMU/KVM installed, NAT network up | Done 2026-10-18 |
| `nutcache` VM created; boot guard unit; stop/start cycle tested | Done 2026-10-18 |
| Emulators (Java, Node, `firebase-tools`) and repo config in `nutcache/` | Done 2026-10-18. Auth, Firestore, Storage and UI running; deny-all rules verified (client read → 403); state survives both a service restart and a full VM shutdown/boot. Functions not configured until the first function exists. |
| Tailscale in the VM (`tag:nutcache`) and tailnet policy | Done 2026-10-18. Joined as `nutcache` (100.103.121.47), tagged, key expiry disabled. Verified: all 7 running emulator ports reachable from the owner's devices, tailnet SSH (22) blocked, and the VM can't reach any other tailnet device. |
| VM firewall (nftables) | Done 2026-10-18. Verified: emulator ports reachable over the tailnet only (blocked from Hooper's private network), SSH and ping from Hooper only, Tailscale still connects directly; loads ~2.4 s into boot, before Tailscale and the emulators. |
| Scheduled backups to `/mnt/backup/nutcache/` | Done 2026-10-18. Nightly at 03:30, 14-day retention. Verified: backup as the systemd service, wipe, restore and data back; pruning removes only archives past 14 days. |

## Storage

Hooper boots from a 58 GB SD card. Everything write-heavy for NutCache lives on the attached external drive instead, both to save SD card wear and because that's where the space is.

- **External drive layout:** a 4.5 TB USB drive, LUKS-encrypted, holding an LVM volume group with two volumes: `/mnt/netstorage` (3.5 TB, general data) and `/mnt/backup` (1 TB, backups). There's no unallocated space in the volume group, and none is needed — NutCache uses directories on the existing volumes rather than its own logical volume.
- **VM disk image:** `/mnt/netstorage/nutcache/nutcache.qcow2`. The downloaded base image is kept alongside in `images/`.
- **Emulator data:** the emulators hold state in memory and start empty unless told otherwise. They're run with `--import` from, and `--export-on-exit` to, `/var/lib/nutcache/emulator-data` on the VM's disk, so state survives a clean restart. systemd stops them with SIGINT, which triggers the export. That includes the VM's ACPI shutdown when Hooper shuts down (tested).
- **Backups:** nightly, to `/mnt/backup/nutcache/`, kept for 14 days. They also bound data loss after an unclean shutdown (power loss skips `--export-on-exit`) to the time since the last backup. See [Backups and Restore](#backups-and-restore) below.
- **Boot-order safeguard:** the external drive is unlocked at boot from a key file and mounted with `nofail`, so Hooper still boots if the drive is missing or fails to unlock — in which case `/mnt/netstorage` is just an empty directory on the SD card. The VM is therefore **not** started with libvirt's plain autostart; it's started by `/etc/systemd/system/nutcache-vm.service` (on Hooper) with `RequiresMountsFor=/mnt/netstorage/nutcache`, so it only starts when the real drive is mounted and never silently writes a fresh VM onto the SD card. The same unit does a clean ACPI shutdown when Hooper shuts down (waiting up to 5 minutes, so the emulators can export), ordered before the drive is unmounted. `libvirt-guests` is explicitly set to `ON_BOOT=ignore` and `ON_SHUTDOWN=shutdown` in `/etc/default/libvirt-guests`, so it can neither start the VM behind the unit's back nor save its 3 GB of RAM to the SD card.

### Backups and Restore

All on Hooper. Sources are in [`nutcache/dev-instance/hooper/`](../../nutcache/dev-instance/hooper/), installed by hand (`deploy.sh` doesn't manage Hooper-side files).

- **`nutcache-backup.timer`** runs **`nutcache-backup.service`** nightly at 03:30 (plus up to 10 minutes' random delay). It has `Persistent=true`, so a night missed while Hooper was off runs at the next boot. The service runs as `tjones` (who owns the `nutcache` SSH key and is in the `libvirt` group), at low CPU and I/O priority, with `RequiresMountsFor=/mnt/backup/nutcache` so it never writes into an empty mount point on the SD card.
- **`/usr/local/bin/nutcache-backup`:**
  - If the VM isn't running (e.g. deliberately stopped for Phase 1 isolation tests), it logs a skip and exits successfully without touching existing backups.
  - Otherwise it waits up to 5 minutes for SSH and for all three emulators (so post-boot catch-up runs don't fail), then asks the Emulator Hub inside the VM to export (`POST /_admin/export` on `127.0.0.1:4400`, which the VM firewall allows on loopback).
  - It streams the export to Hooper as one `nutcache-YYYYMMDD-HHMMSS.tar.gz`, verifies the gzip and that it contains the export metadata, and only then deletes archives older than 14 days. Since pruning only follows a successful backup, a long VM outage never prunes away the last good backups.
- **`/usr/local/bin/nutcache-restore <archive>`:** streams the archive into the VM, stops the emulators (exporting their current state), moves that state aside to `/var/lib/nutcache/emulator-data.pre-restore` (replacing any earlier one), swaps the backup in, and restarts the emulators, which import it.
- **Checking on it:** `systemctl list-timers nutcache-backup.timer` and `journalctl -u nutcache-backup`.

## What Runs Inside the VM: Firebase Local Emulator Suite

The VM runs Google's official [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite), emulating Firestore, Auth, Cloud Functions, and Cloud Storage locally — the same four Firebase products ADR 0006 chose for the real backend.

This matters for how clean the eventual transition is: the mobile app talks to the **same Firebase client SDK APIs** whether it's pointed at the NutCache dev instance or the real cloud project. There's no separate "local backend API" to build or throw away — dev builds just configure the Firebase SDK to connect to the emulator endpoints on `nutcache` instead of a live project.

The NutCache configuration the emulators run from — `firebase.json`, Firestore security rules and indexes, Storage rules, and Cloud Functions source — is version-controlled in this repository, not clicked together in the emulator UI. That's what makes the transition to a real project a deploy rather than a rebuild (see Transition Plan, step 2).

## Network: Tailnet-Only Access

NutCache dev is reachable **only over the owner's Tailscale tailnet** — not on the home LAN, not via port forwarding through Hooper, and never on the public internet. Tailscale's WireGuard tunnel supplies both encryption and peer authentication, and it works the same at home and away from it (including over cellular), so one hostname — `nutcache.tail37f114.ts.net` — is used everywhere.

### Devices on the Tailnet

| Device | Role for NutManager |
|---|---|
| `hooper` | Hosts the VM. Exposes **no** NutCache ports itself; its existing tailnet-reachable services are unaffected. |
| `quint` (Linux laptop) | Developer workstation: Emulator UI in a browser, and scripts/tests run against NutCache. |
| `teds-xcover7-pro` | Test phone EQ-D1. Tailscale must be connected for Phase 2+ tests. |
| Second test device (EQ-D2) | Needed from Phase 2 for the two-device household tests. Joins under the owner's account. |
| `nutcache` | The VM. Joins as a **tagged** device (`tag:nutcache`) rather than as the owner's user, so tailnet policy can restrict it independently; tagged devices also don't have node key expiry, which suits a server. |

A tailnet device is connected to all other permitted devices at once — there's no switching between `hooper` and `nutcache`.

### Ports Served on `nutcache`

All are plain HTTP or WebSocket, carried inside the WireGuard tunnel. None has any access control of its own beyond tailnet membership (see "What tailnet access implies" below).

| Port | Service | What it serves | Used by |
|---|---|---|---|
| 4000 | Emulator Suite UI | Web admin console: browse/edit Firestore documents, Auth users, Storage files; view function logs; Firestore request monitor showing which security rule allowed/denied each request. | Developer's browser (EQ-S3) |
| 4400 | Emulator Hub | Small REST API for discovering which emulators are running on which ports; also exposes data-export endpoints. | UI, CLI, test tooling, backup job |
| 4500 | Logging | WebSocket stream of emulator logs. | UI's Logs tab |
| 9150 | Firestore WebSocket | Live Firestore request monitoring. | UI's Firestore Requests tab |
| 9099 | Auth emulator | Firebase Auth REST APIs (sign-up/sign-in/token refresh), plus emulator-only endpoints to list/delete all users and read verification/reset codes. | App sign-in; tests creating EQ-A1 accounts |
| 8080 | Firestore emulator | The database, over gRPC and REST on one port. Phase 2 contents: households/membership, shopping lists and items (LIST-1, LIST-7), the barcode database (BC-1, BC-2, BC-4), synced offline changes (SYNC-2). **Security rules are enforced here** (CLOUD-2). | App; rules tests (AT2.5); sync tests (AT2.1, AT2.2) |
| 5001 | Functions emulator | Cloud Functions from the repo: HTTP/callable endpoints at `/demo-nutcache/<region>/<function>`, plus Firestore-triggered functions running internally. Server-computed fields (CLOUD-3) are produced here. Functions run with admin privileges, bypassing security rules. | App callable functions; tests |
| 9199 | Storage emulator | Cloud Storage for uploaded files (e.g. label/price-tag/coupon images in later phases). Storage security rules enforced. | App (later phases) |

**Deliberately not running:** Hosting (5000), Realtime Database (9000), Pub/Sub (8085), Eventarc (9299), Data Connect (9399) — none is used per ADR 0006. The Functions debugger/inspector port (9229) stays off unless enabled for a specific debugging session.

### What Tailnet Access Implies

Any device that can reach these ports can do anything to NutCache dev's data:

- Firestore and Storage emulators bypass security rules entirely for requests carrying `Authorization: Bearer owner`. Rules only constrain well-behaved clients like the app — they are tested here, not relied on for protection.
- The Auth emulator issues unsigned tokens and will sign in as any user.
- The Hub and Auth emulator expose unauthenticated export and delete-all endpoints.

Therefore:

- **Tailnet membership is the entire access control.** Never enable Tailscale Funnel for `nutcache`, and never share the device outside the tailnet.
- **Test data only.** No real personal or health data goes into NutCache dev, consistent with [ADR 0020](../adrs/Accepted/0020-health-data-privacy-and-hipaa.md).
- The go-live consequences of relying on the tailnet are tracked in [securing_nuts.md](../securing_nuts.md) (SEC-1 to SEC-7).

### Non-Tailnet Interfaces on the VM

| Interface / direction | What's there |
|---|---|
| libvirt NAT network (`192.168.122.0/24`, reachable only from Hooper itself) | SSH, for administration from Hooper and for the backup job. Emulator ports are firewalled off on this interface. |
| Home LAN | Nothing. The VM isn't bridged onto the LAN, and Hooper forwards nothing to it. |
| Tailscale SSH | Off. Administration goes through Hooper. Can be enabled later if direct SSH from the laptop is wanted. |
| Outbound | Package installs, the one-time emulator binary download, Tailscale's own control/relay traffic. The `demo-` project ID prevents Functions code from reaching real Google services. |

### Joining the Tailnet

One-time, after `provision-vm.sh` has installed Tailscale. The auth key is generated in the admin console (Settings → Keys): tagged `tag:nutcache`, **not ephemeral** (ephemeral devices are removed whenever they go offline), not reusable, short expiry. The key never enters the repo or the VM's disk: it's saved to a mode-600 file on Hooper, piped to the VM over SSH, and the file is shredded afterwards:

```sh
tr -d '[:space:]' < ~/nutcache-authkey | ssh nutcache 'sudo tailscale up --auth-key=file:/dev/stdin \
    --hostname=nutcache --advertise-tags=tag:nutcache --accept-dns=false'
shred -u ~/nutcache-authkey
```

`--accept-dns=false` keeps the VM's own DNS unchanged; it never needs to resolve tailnet names. Hooper also has Tailscale DNS off, so `nutcache.tail37f114.ts.net` doesn't resolve *on Hooper* (use `ssh nutcache` or the `100.x` address there). It resolves normally on devices with MagicDNS enabled, which is what the app relies on.

**Emulator UI from other devices:** the Hub advertises every emulator as `127.0.0.1`, but because they *listen* on `0.0.0.0`, the UI's browser code substitutes the hostname the page was loaded from. Opening `http://nutcache.tail37f114.ts.net:4000` therefore makes the UI talk to the emulators at that same name.

### Defense Layers

1. **Tailnet policy** (outermost): owner's devices may reach `tag:nutcache` only on the eight ports above; `tag:nutcache` may initiate **no** connections to other tailnet devices, so a compromised VM can't reach Hooper's services. Tailscale's default allow-all grant (`"src": ["*"]`) would include tagged devices as sources, so it's replaced. Policy, in Tailscale's grants syntax (set in the admin console's JSON editor):

   ```jsonc
   {
     "tagOwners": {
       "tag:nutcache": ["autogroup:admin"],
     },
     "grants": [
       // The owner's own devices can reach each other on all ports (replaces the default allow-all grant).
       {"src": ["autogroup:member"], "dst": ["autogroup:self"], "ip": ["*"]},
       // The owner's devices can reach the NutCache dev emulator ports, and nothing else on nutcache.
       {"src": ["autogroup:member"], "dst": ["tag:nutcache"],
        "ip": ["tcp:4000", "tcp:4400", "tcp:4500", "tcp:9150", "tcp:9099", "tcp:8080", "tcp:5001", "tcp:9199"]},
       // No grant has tag:nutcache as a source, so nutcache cannot initiate connections to anything.
     ],
   }
   ```

   Any existing `ssh` or other sections of the policy are kept as they are.

2. **VM firewall (nftables):** emulator ports accepted on `tailscale0` only; SSH and ping accepted only from Hooper (`192.168.122.1`) on the libvirt interface; Tailscale's WireGuard port (UDP 41641) and DHCP renewals accepted on that interface; everything else inbound dropped. The rules ([`nutcache/dev-instance/nutcache-firewall.nft`](../../nutcache/dev-instance/nutcache-firewall.nft)) live in their own table, `inet nutcache`, loaded early in boot by `nutcache-firewall.service`, and leave Tailscale's own netfilter tables alone. Debian's stock `nftables.service` is deliberately not used: it runs `nft flush ruleset` on stop, which would also wipe Tailscale's rules. `deploy.sh` applies firewall changes with a dead man's switch: a timer in the VM removes the table after 90 s unless a fresh SSH login from Hooper succeeds.
3. **Emulator binding:** the emulators listen only on the VM's own interfaces; nothing is reachable via any Hooper address.

### Why Plain HTTP Rather Than HTTPS

Using HTTPS end to end was considered and rejected, because the Firebase SDKs don't support it for most emulators:

- The Android Auth, Functions, and Storage SDKs' emulator modes hard-code `http://` connections, with no TLS option.
- Firestore alone could be pointed at an HTTPS host (e.g. via `tailscale serve` TLS termination), but that would add configuration without removing the need for a cleartext exception for the other three.
- The Emulator UI's page connects directly to ports 4400/4500/9150 over plain HTTP/WS, which browsers block as mixed content if the UI itself is served over HTTPS.
- Tailscale HTTPS certificates are logged in public Certificate Transparency logs, publishing the tailnet and device names.

What mitigates it:

- On the wire, traffic is inside WireGuard: encrypted, and authenticated to the `nutcache` device's key.
- The app's Android cleartext exception (a network security config `domain-config`) is scoped to `nutcache.tail37f114.ts.net` in **debug builds only**. Release builds keep Android's default cleartext block, and production NutCache (real Firebase) is HTTPS.
- The app addresses NutCache by its MagicDNS name, never the raw `100.x` IP. If Tailscale is off on the device the name simply fails to resolve, whereas a hard-coded `100.x` address could be routed over a mobile carrier's network (carriers use the same CGNAT range).

## Testing Implications

- "Online" for NutCache dev means "Tailscale connected," from anywhere — the home LAN is irrelevant. That makes functional testing away from home (including an actual in-store trip over cellular) possible before the real cloud backend exists.
- It is still **not representative of real-world backend connectivity**: latency to a Pi through Tailscale (possibly via a relay) and a single-host availability profile say nothing about a real cloud endpoint. This matters for testing the assumptions in [ADR 0005](../adrs/Accepted/0005-offline-local-storage-and-sync.md) (offline-first in-store shopping) and [ADR 0015](../adrs/Accepted/0015-cloud-local-split-nutrition-planning.md) (cloud-first nutrition planning, which assumes general connectivity): both can be functionally tested against NutCache dev, but performance/latency conclusions need the real backend.
- **Phase 1 isolation:** Phase 1 tests must run with NutCache unreachable. Either disconnect Tailscale on the test device or shut the VM down — airplane mode alone isn't enough, and neither is being off the home Wi-Fi, since Tailscale works over any network.

## Known Limitations

Being upfront about what this setup is *not*:

- **Single point of failure**, no uptime guarantees. Backups are the nightly exports described under Storage, to a different volume on the *same* external drive: they protect against data mistakes and VM breakage, not against losing the drive or Hooper. No replication or offsite copy (acceptable for test data).
- **Limited concurrency/performance headroom** — a Pi running a VM running the emulator suite (the Firestore emulator alone runs on a JVM) has a low ceiling. Fine for one developer clicking through the app; not a substitute for any real load or performance testing.
- **No access control beyond the tailnet.** See "What Tailnet Access Implies." Never exposed via Funnel, port forwarding, or the public internet.
- **Emulator behavior can subtly diverge from production** — quota/rate-limit behavior, and occasionally newer API surface, may not be perfectly emulated. Don't treat "works against the emulator" as a guarantee it'll behave identically against the real service.

## Transition Plan to Real Cloud Infrastructure

**Trigger conditions** (any of these means it's time to move NutCache off Hooper):

- Field testing needs realistic backend latency/availability, not just functional connectivity (which the tailnet already provides).
- A developer or tester outside the owner's tailnet needs access to a shared backend.
- Need to validate behavior against real Firebase quotas, billing, or performance characteristics.
- Approaching a releasable prototype milestone.

**Steps:**

1. Create a real Firebase project (consider whether separate dev/staging vs. production Firebase projects are wanted — that's a decision for its own discussion when this becomes relevant, not decided here).
2. Deploy the existing Firestore security rules, indexes, Storage rules, and Cloud Functions from version-controlled source to the real project. These are already tracked as source alongside the app, so this step is a deploy, not a rebuild.
3. Repoint the mobile app's build configuration (e.g., Flutter build flavors / environment-specific Firebase config files) from the NutCache dev emulator endpoints to the live Firebase project, and drop the debug-only cleartext exception if no build flavor still needs it.
4. Re-run the functional test suite against the live project before relying on it for anything real.
5. Before any real users or real data: every entry in [securing_nuts.md](../securing_nuts.md) is Done or recorded as not applicable. Several entries (SEC-1 to SEC-7) come from this setup.
6. Decommission the `nutcache` VM (remove it from the tailnet and the tailnet policy) once it's no longer needed. Hooper itself continues in its other roles.

## Open Questions

- Whether dev/staging/production Firebase project separation eventually warrants its own ADR — not decided here; this document only describes the current interim local setup.
