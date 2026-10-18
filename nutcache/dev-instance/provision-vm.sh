#!/bin/sh
# Provisions the nutcache VM for the NutCache dev instance. Run inside the VM as the admin user
# (deploy.sh does this over SSH). Idempotent: safe to re-run.
#
# Installs Tailscale but doesn't join the tailnet: that's a one-time step needing a tag:nutcache auth key
# (see "Joining the tailnet" in docs/design/nutcache-dev-instance.md).
set -eu

FIREBASE_TOOLS_VERSION=15.34.0
NODE_MAJOR=22

sudo apt-get -q update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -q install ca-certificates curl gnupg rsync locales qemu-guest-agent

# en_US.UTF-8, so SSH sessions from Hooper don't warn about a missing locale.
echo "en_US.UTF-8 UTF-8" | sudo tee /etc/locale.gen >/dev/null
sudo locale-gen >/dev/null

# Java 21 (required by firebase-tools for the Firestore emulator; Debian 12 only has 17): Eclipse Temurin.
# Node.js 22 LTS (a supported Cloud Functions runtime): NodeSource.
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor --yes -o /etc/apt/keyrings/adoptium.gpg
echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" | sudo tee /etc/apt/sources.list.d/adoptium.list >/dev/null
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
# Tailscale: the VM joins the owner's tailnet as its own device (tag:nutcache); see the design note.
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /etc/apt/keyrings/tailscale.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/tailscale.gpg] https://pkgs.tailscale.com/stable/debian bookworm main" | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
sudo apt-get -q update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -q install temurin-21-jre nodejs tailscale

if [ "$(firebase --version 2>/dev/null || true)" != "$FIREBASE_TOOLS_VERSION" ]; then
  sudo npm install -g --no-fund --no-audit "firebase-tools@$FIREBASE_TOOLS_VERSION"
fi

# Service account and directories. Config is owned by the admin user (deploy.sh rsyncs into it) and
# group-writable by nutcache, because firebase-tools writes its *-debug.log files into the project dir.
id nutcache >/dev/null 2>&1 || sudo useradd --system --home-dir /var/lib/nutcache --shell /usr/sbin/nologin nutcache
sudo install -d -o nutcache -g nutcache -m 0750 /var/lib/nutcache /var/lib/nutcache/emulator-data
sudo install -d -o "$(id -un)" -g nutcache -m 2775 /opt/nutcache /opt/nutcache/config
