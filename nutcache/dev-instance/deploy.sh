#!/bin/sh
# Deploys NutCache config to the dev instance. Run on Hooper from anywhere in the repo checkout.
#
#   deploy.sh              sync config + service files; restart the emulators only if needed
#   deploy.sh --provision  also (re)run provision-vm.sh in the VM first
#   deploy.sh --restart    force an emulator restart (state is exported and re-imported)
#
# Rules files are hot-reloaded by the emulators, so a rules-only change takes effect without a restart.
# See docs/design/nutcache-dev-instance.md.
set -eu

VM=nutcache   # SSH alias in Hooper's ~/.ssh/config
SRC=$(cd "$(dirname "$0")/.." && pwd)   # the repo's nutcache/ directory
PROVISION=no RESTART=no
for arg in "$@"; do
  case "$arg" in
    --provision) PROVISION=yes ;;
    --restart) RESTART=yes ;;
    *) echo "usage: $0 [--provision] [--restart]" >&2; exit 2 ;;
  esac
done

if [ "$PROVISION" = yes ]; then
  ssh "$VM" 'sh -s' < "$SRC/dev-instance/provision-vm.sh"
fi

# Config: everything in nutcache/ except the dev-instance plumbing. -c compares content, so an
# unchanged file isn't reported as changed just because its timestamp differs.
CHANGED=$(rsync -rlc --delete --itemize-changes --exclude=/dev-instance/ --exclude='*-debug.log' \
  "$SRC/" "$VM:/opt/nutcache/config/" | grep -v '^\.' || true)
[ -n "$CHANGED" ] && printf 'config changes:\n%s\n' "$CHANGED"
echo "$CHANGED" | grep -qE 'firebase\.json|\.firebaserc|firestore\.indexes\.json' && RESTART=yes

# Service wrapper and unit.
rsync -c "$SRC/dev-instance/nutcache-emulators" "$SRC/dev-instance/nutcache-emulators.service" "$VM:/tmp/"
UNIT_CHANGED=$(ssh "$VM" 'c=no
  sudo cmp -s /tmp/nutcache-emulators /usr/local/bin/nutcache-emulators || { sudo install -m 0755 /tmp/nutcache-emulators /usr/local/bin/; c=yes; }
  sudo cmp -s /tmp/nutcache-emulators.service /etc/systemd/system/nutcache-emulators.service || { sudo install -m 0644 /tmp/nutcache-emulators.service /etc/systemd/system/; sudo systemctl daemon-reload; c=yes; }
  sudo systemctl enable -q nutcache-emulators.service
  echo $c')
[ "$UNIT_CHANGED" = yes ] && RESTART=yes

if ! ssh "$VM" 'systemctl is-active -q nutcache-emulators'; then
  echo "starting emulators"; ssh "$VM" 'sudo systemctl start nutcache-emulators'
elif [ "$RESTART" = yes ]; then
  echo "restarting emulators (state is exported and re-imported)"; ssh "$VM" 'sudo systemctl restart nutcache-emulators'
else
  echo "emulators already running; no restart needed"
fi
