# NutCache

Source for **NutCache**, the server side of NutManager (see the naming conventions in the [top-level README](../README.md#naming-conventions)). Everything that defines NutCache's behavior lives here, version-controlled. That's what lets the move from the dev instance to a real Firebase project be a deploy rather than a rebuild ([transition plan](../docs/design/nutcache-dev-instance.md#transition-plan-to-real-cloud-infrastructure), step 2).

## Layout

| Path | What it is |
|---|---|
| `firebase.json` | Firebase project config: which products are used, where their rules and indexes live, and the emulator ports for the dev instance. |
| `.firebaserc` | Default project: `demo-nutcache`. The `demo-` prefix makes it emulator-only. |
| `firestore.rules` | Firestore security rules: the production access boundary (SEC-1 in [securing_nuts.md](../docs/securing_nuts.md)). Currently deny-all. Phase 2 adds the real household-scoped rules and their tests (AT2.5). |
| `firestore.indexes.json` | Firestore composite indexes. Currently none. |
| `storage.rules` | Cloud Storage security rules. Currently deny-all. |
| `dev-instance/` | Plumbing for the NutCache dev instance on Hooper. Not deployed to Firebase. |

Cloud Functions aren't configured yet. When the first function is written, add its source (e.g. `functions/`) and a `functions` entry in `firebase.json`, and set the Functions emulator to port 5001 under `emulators`, as listed in the design note.

## Dev Instance

The dev instance is the Firebase Local Emulator Suite running in the `nutcache` VM on Hooper. It's described in [docs/design/nutcache-dev-instance.md](../docs/design/nutcache-dev-instance.md).

| File | Runs on | Purpose |
|---|---|---|
| `dev-instance/deploy.sh` | Hooper | Syncs this directory's config to the VM, installs the service files, and restarts the emulators only when needed. `--provision` re-runs VM provisioning first; `--restart` forces a restart. Firewall changes are applied with an automatic rollback guard. |
| `dev-instance/provision-vm.sh` | VM (via `deploy.sh --provision`) | Idempotent VM setup: Java 21 (Temurin), Node.js 22 (NodeSource), a pinned `firebase-tools` version, the `nutcache` service account, and directories. |
| `dev-instance/nutcache-emulators` | VM, `/usr/local/bin/` | Starts the emulators: imports saved state if there is any, and exports on a clean stop. |
| `dev-instance/nutcache-emulators.service` | VM, `/etc/systemd/system/` | systemd unit for the above, running as the `nutcache` user. |
| `dev-instance/nutcache-firewall.nft` | VM, `/etc/nutcache/firewall.nft` | Inbound firewall: emulator ports on the tailnet only, SSH and ping from Hooper only. Its own nftables table; Tailscale's rules are untouched. |
| `dev-instance/nutcache-firewall.service` | VM, `/etc/systemd/system/` | Loads the firewall early in boot. `deploy.sh` applies changes with an automatic 90-second rollback unless SSH from Hooper still works afterwards. |
| `dev-instance/hooper/nutcache-vm.service` | Hooper, `/etc/systemd/system/` | Reference copy of the unit that starts the VM only when the external drive is mounted. It's installed by hand; `deploy.sh` doesn't manage it. |

### Common tasks

All run on Hooper, from the repo checkout:

```sh
nutcache/dev-instance/deploy.sh             # after changing anything in nutcache/
nutcache/dev-instance/deploy.sh --restart   # restart the emulators (state is exported and re-imported)
ssh nutcache                                # shell in the VM
ssh nutcache 'sudo journalctl -u nutcache-emulators -f'   # follow emulator logs
```

- **Rules changes** take effect without a restart: the emulators hot-reload rules files. Changes to `firebase.json`, `.firebaserc`, indexes, or the service files trigger a restart automatically.
- **State** lives in `/var/lib/nutcache/emulator-data` in the VM. It's exported on every clean stop, including when Hooper shuts down, and imported on start.
- **Startup time:** about 20 seconds for a restart, and about 1¾ minutes after a cold VM boot, while Java starts up on the Pi.
