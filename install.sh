#!/usr/bin/env bash
# Sets up a machine: macOS, Debian/Ubuntu/Mint, Fedora or Arch.
# Usage: ./install.sh                 packages + configs
#        ./install.sh --configs-only  configs only, packages untouched
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/stage_common.sh"

log "Dotfiles: $DOTFILES_DIR"

if [ "${1:-}" = "--configs-only" ]; then
  install_configs
  log "Configs applied. Open a new terminal (or run: exec zsh)."
  bash "$SCRIPT_DIR/doctor.sh" || true
  exit 0
fi

os="$(detect_os)"
log "Detected: $(os_description)"
# "$os" is the package-manager family the stages branch on, not the distro's name.
log "Package family: $os"

case "$os" in
  macos)                 bash "$SCRIPT_DIR/macos/setup.sh" ;;
  debian|fedora|arch)    bash "$SCRIPT_DIR/linux/setup.sh" ;;
  *) err "Unsupported OS. Supported: macOS, Debian/Ubuntu/Mint, Fedora, Arch."; exit 1 ;;
esac

# The OS stage ran as a subprocess, so the Homebrew it just installed is not on PATH here.
# Without this the common stage silently skips everything brew provides: rbenv (so no
# Ruby), gh (so no copilot extension), node.
load_brew || warn "Homebrew not found; the common stage will skip what depends on it"

run_common_stage

log "Verifying the shell environment"
bash "$SCRIPT_DIR/doctor.sh" || true

log "Done. Open a new terminal (or run: exec zsh)."
