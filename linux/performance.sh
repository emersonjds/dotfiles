#!/usr/bin/env bash
# Kernel and service tuning for a development machine.
#
# Nothing here is a benchmark trick. Each change addresses something that either wastes
# resources on a box with plenty of them, or breaks a normal development workflow.
#
# Services are only disabled when the hardware they exist for is absent. Bluetooth is
# never touched: on a laptop it is often the keyboard and mouse.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

SYSCTL_FILE=/etc/sysctl.d/99-dotfiles-dev.conf

if ! sudo -n true 2>/dev/null && [ ! -w /etc/sysctl.d ]; then
  warn "performance tuning needs sudo; run ./linux/performance.sh directly"
  exit 0
fi

# --- kernel -----------------------------------------------------------------------
# swappiness 60 is tuned for a machine that might actually need swap. With 8 GB or more
# and an SSD it just evicts pages that are about to be read again.
#
# vfs_cache_pressure 50 keeps dentry and inode caches around longer, which is what a
# source tree of tens of thousands of small files is made of.
#
# inotify watches are the one that bites: every file watcher (a bundler, a test runner,
# an IDE) takes one per directory, and node_modules alone can hold tens of thousands.
# Running out shows up as a watcher that silently stops noticing changes.
log "Kernel tuning -> $SYSCTL_FILE"
sudo tee "$SYSCTL_FILE" >/dev/null <<'EOF'
# Managed by dotfiles (linux/performance.sh).

# Plenty of RAM and an SSD: stop swapping pages that are still warm.
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# File watchers. The defaults run out on a large node_modules and the watcher then
# stops reporting changes without erroring.
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
EOF
sudo sysctl -q --system >/dev/null 2>&1 || warn "could not reload sysctl"
ok "swappiness=$(cat /proc/sys/vm/swappiness) watches=$(cat /proc/sys/fs/inotify/max_user_watches)"

# --- power ------------------------------------------------------------------------
# intel_pstate parks the cores well below their turbo range under the balanced profile.
if command_exists powerprofilesctl; then
  powerprofilesctl set performance 2>/dev/null \
    && ok "power profile: performance (persists across reboots)" \
    || warn "could not set the power profile"
fi

# --- services ---------------------------------------------------------------------
# Only ever disabled when the thing they serve is not present.
disable_if() {  # <service> <human reason>
  local svc="$1" why="$2"
  systemctl is-enabled "$svc" >/dev/null 2>&1 || return 0
  sudo systemctl disable --now "$svc" >/dev/null 2>&1 \
    && ok "disabled $svc ($why)" \
    || warn "could not disable $svc"
}

# No printer configured, and cups-browsed additionally polls the network for them.
if ! lpstat -p >/dev/null 2>&1; then
  disable_if cups.service "no printer configured"
  disable_if cups-browsed.service "no printer configured"
else
  log "printer found; leaving cups alone"
fi

# No WWAN hardware. ModemManager otherwise probes serial devices at every boot.
if ! mmcli -L 2>/dev/null | grep -q /Modem/; then
  disable_if ModemManager.service "no mobile broadband hardware"
fi

# Holds up graphical.target waiting for a route that a laptop gets seconds later anyway.
disable_if NetworkManager-wait-online.service "delays boot, gains nothing on a laptop"

# Left over from the live installer; it fails on every boot and shows up in --failed.
if systemctl is-failed casper-md5check.service >/dev/null 2>&1; then
  sudo systemctl mask casper-md5check.service >/dev/null 2>&1 \
    && ok "masked casper-md5check (live-ISO leftover, fails every boot)"
fi

log "Performance tuning done. Bluetooth left enabled on purpose: it is often the keyboard."
