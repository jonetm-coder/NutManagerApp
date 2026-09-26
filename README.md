# NutManagerApp

A mobile app, part of a larger ecosystem with cloud storage/processing (the server side, **NutCache**), that lets a user scan a product label, classify the product, and match it to a shopping list — while offline, in-store. The broader ecosystem also covers pricing/coupon capture, cross-user data sharing, and a full nutrition planning & health-tracking system.

See [CLAUDE.md](CLAUDE.md) for the full project summary, and [docs/adrs/](docs/adrs/) for the architectural decisions driving the design (still being worked through — see Project Status below).

## Naming Conventions

**NutManager** is short for *Nutrition Manager*. "Nut" works twice over: it's nutrition, and it's what squirrels (and chipmunks) carefully gather, store, and guard. Major pieces of the system follow that theme:

| Name | What it is | Why the name |
|---|---|---|
| **NutManager** | The project as a whole, and the mobile app. The repository is `NutManagerApp`. | Nutrition Manager. |
| **NutCache** | The server side: the cloud services that store shopping lists, recipes, nutrition and pricing data, per [ADR 0006](docs/adrs/Accepted/0006-cloud-backend-platform.md). Its current development instance runs on Hooper; see [docs/design/nutcache-dev-instance.md](docs/design/nutcache-dev-instance.md). | A squirrel's cache is where the nuts are stored. |
| **Securing NUTS** | Security across the whole infrastructure, tracked in [docs/securing_nuts.md](docs/securing_nuts.md): every development-time security shortcut and what must happen before go-live. | Making sure no other squirrels steal our nuts. |

**Hooper** is the name of the Raspberry Pi that hosts the NutCache dev instance. It's an existing machine with its own name and other jobs, not part of the theme.

When a new major component needs a name, keep it in the theme where it fits naturally, and add it to this table.

### Identifiers

Where a name appears in code, infrastructure, or configuration, it's lower-case with no spaces:

| Context | Form | Example |
|---|---|---|
| Hostnames, VM names, tailnet devices | lower-case | `nutcache`, `nutcache.tail37f114.ts.net` |
| Firebase project IDs | lower-case, hyphenated; `demo-` prefix for emulator-only | `demo-nutcache`; later e.g. `nutcache-dev`, `nutcache-prod` |
| Tailscale tags | `tag:` + lower-case name | `tag:nutcache` |
| Filesystem paths on hosts | lower-case name as the directory | `/mnt/netstorage/nutcache/`, `/mnt/backup/nutcache/` |
| Prose and document titles | CamelCase product names | NutManager, NutCache |

## Project Status

This project is in the **architecture/design phase**. No application code has been written yet; the current output of the project is a set of Architectural Decision Records (ADRs) exploring the tradeoffs for each major piece of the system, plus a requirements document derived from them.

- [docs/adrs/Proposed/](docs/adrs/Proposed/) — ADRs under discussion, not yet decided.
- [docs/adrs/README.md](docs/adrs/README.md) — the ADR process (Proposed → Accepted/Rejected).
- [docs/requirements.md](docs/requirements.md) — functional requirements derived from accepted (and, for now, some still-proposed) ADRs, each with a priority and acceptance criteria.

The mobile client direction (see [ADR 0001](docs/adrs/Proposed/0001-mobile-app-framework.md), currently Proposed) is **Flutter**, targeting Android first with iOS to follow. The setup instructions below build a Flutter development environment accordingly.

## Documentation

- [CLAUDE.md](CLAUDE.md) — project overview and workflow, written for AI-assisted development with Claude Code.
- [docs/requirements.md](docs/requirements.md) — requirements.
- [docs/adrs/](docs/adrs/) — architectural decision records.
- [docs/design/nutcache-dev-instance.md](docs/design/nutcache-dev-instance.md) — the NutCache development instance on Hooper.
- [docs/securing_nuts.md](docs/securing_nuts.md) — Securing NUTS: the go-live security ledger.

## Development Environment Setup — Flutter on Kali Linux with VS Code

These instructions assume **Kali GNU/Linux (Rolling)** and **VS Code** as the daily-driver editor.

> **Status on this machine (2026-08-23):** Flutter 3.47.1, the Android SDK (command-line-tools only, no Android Studio needed), and the VS Code Dart/Flutter extensions are installed and `flutter doctor` reports Flutter, Android toolchain, Linux toolchain, and a connected device all green. Two things are still outstanding and need to be done by hand (see step 4): adding your user to the `kvm` group for hardware-accelerated emulation, and a logout/login for that to take effect. Chrome isn't installed (only needed for the web target, not required for Android).

### 1. Prerequisites

Kali is Debian-based, so standard `apt` packages apply. Install the base tools Flutter's tooling expects:

```bash
sudo apt update
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev
```

- `git`, `curl`, `unzip`, `xz-utils`, `zip` — needed by the Flutter tool itself.
- `libglu1-mesa` — needed for the Android emulator.
- `clang cmake ninja-build pkg-config libgtk-3-dev` — needed for the Linux desktop target; already installed on this machine (`flutter doctor` shows the Linux toolchain check passing).

This machine's system JDK (`openjdk 25`) works fine with the current Flutter/Android Gradle Plugin — `flutter doctor` picked it up automatically with no configuration needed. If a future Flutter/AGP version pair complains about JDK compatibility, point Flutter at a specific JDK with `flutter config --jdk-dir=/path/to/jdk`.

### 2. Install the Flutter SDK

Two common options — pick one:

**Option A — official tarball (recommended, most predictable):**

```bash
cd ~/development   # or wherever you keep SDKs; create the dir if needed
git clone https://github.com/flutter/flutter.git -b stable
```

Then add Flutter to your `PATH`. Since your shell is zsh, add this to `~/.zshrc`:

```bash
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
```

**Option B — snap package (simpler, less control over version):**

```bash
sudo snap install flutter --classic
```

Verify either way:

```bash
flutter --version
```

Dart comes bundled with Flutter — no separate install needed.

### 3. Android toolchain

Flutter needs the Android SDK, platform-tools (`adb`), and a platform/build-tools version matching what the installed Flutter release expects. **Android Studio is not required** — the command-line tools alone are enough, and that's what's set up on this machine:

```bash
mkdir -p ~/Android/Sdk/cmdline-tools
curl -L -o /tmp/commandlinetools.zip "https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip"
unzip -q /tmp/commandlinetools.zip -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
rm /tmp/commandlinetools.zip
```

(The exact `commandlinetools-linux-*` filename changes over time — check https://developer.android.com/studio#command-tools for the current one if this URL ever 404s.)

Set the SDK location for your shell (add to `~/.zshrc`):

```bash
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator"' >> ~/.zshrc
source ~/.zshrc
```

Install the SDK packages and accept the licenses (non-interactively, via `yes |`):

```bash
yes | sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-36" "build-tools;36.0.0"
yes | sdkmanager --licenses --sdk_root="$ANDROID_HOME"
```

`platforms;android-36` / `build-tools;36.0.0` are what the currently-installed Flutter (3.47.1) asked for specifically — `flutter doctor -v` will tell you the exact version it wants if a future Flutter upgrade changes that; adjust the package names accordingly (run `sdkmanager --list` to see what's available).

Point Flutter at the SDK:

```bash
flutter config --android-sdk "$ANDROID_HOME"
```

**Want Android Studio anyway?** It's not needed for anything above, but it does give you a GUI SDK/AVD Manager if you'd rather click through creating emulators than use `avdmanager` on the command line. Download it from https://developer.android.com/studio, point it at the same `~/Android/Sdk` when it asks, and keep using VS Code as your actual editor — Android Studio would purely be a SDK/emulator management tool in that case.

### 4. Android emulator vs. physical device

- **Emulator**: this machine has `/dev/kvm` present, which means hardware-accelerated emulation should work *if* your user account is in the `kvm` group *and*, if Kali itself is running inside a VM (VMware/VirtualBox/etc. — this account has a `vboxsf` group, suggesting it might be), nested virtualization is enabled on the host.
  - **Outstanding on this machine**: `bear` is not yet in the `kvm` group. Run `sudo usermod -aG kvm "$USER"`, then **fully log out and back in** (a new shell alone isn't enough — group membership is set at login) for it to take effect. Verify with `groups` afterward.
  - Once that's done, install a system image and create an AVD, e.g.: `sdkmanager "system-images;android-36;google_apis;x86_64"` then `avdmanager create avd -n pixel -k "system-images;android-36;google_apis;x86_64"`, and run it with `emulator -avd pixel`.
- **Physical Android device** (often simpler and faster than an emulator, and sidesteps the `kvm`/nested-virtualization question entirely): enable Developer Options and USB debugging on the phone, connect via USB, and confirm the debugging prompt on the device. Run `adb devices` to verify it's detected. If it doesn't show up, you likely need a udev rule for your device's vendor ID — see https://developer.android.com/studio/run/device.

### 5. VS Code setup

Already done on this machine — the two extensions that matter are installed:

```bash
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
```

The Flutter extension pulls in the Dart extension's functionality (debugging, hot reload, widget inspector, `flutter` commands from the Command Palette) — installing both is fine and is what most setups do.

### 6. Verify everything

```bash
flutter doctor -v
```

Current state on this machine:

```
[✓] Flutter (Channel stable, 3.47.1, on Kali GNU/Linux Rolling ...)
[✓] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
[✗] Chrome - develop for the web (Cannot find Chrome executable at google-chrome)
[✓] Linux toolchain - develop for Linux desktop
[✓] Connected device (1 available)
[✓] Network resources
```

Chrome is only needed for the web target — not required for Android development, safe to ignore unless/until web support is pursued. Everything needed for Android is green.

### 7. iOS — a heads-up, not a blocker yet

iOS builds require **Xcode, which only runs on macOS** — there is no way to build or run the iOS app from Kali Linux. Per [ADR 0001](docs/adrs/Proposed/0001-mobile-app-framework.md), iOS is planned to follow the Android prototype, so this isn't needed yet. When that phase starts, the options are: a physical Mac, a cloud Mac CI service (e.g., Codemagic, GitHub Actions macOS runners), or a Mac-in-the-cloud rental service. Flutter's cross-platform code can still be written and reviewed from Kali in the meantime; only the actual iOS build/run step needs a Mac.

## Next Steps

Once `flutter doctor` is clean:

```bash
flutter create --org <your-reverse-domain> nut_manager_app
```

This will scaffold the actual Flutter project (not yet present in this repository) and generate its own `.gitignore`, `pubspec.yaml`, and platform folders. That scaffolding, and where it lives relative to `docs/`, is a good candidate for its own short discussion (or ADR, if any nontrivial structural decision comes up) before committing it.
