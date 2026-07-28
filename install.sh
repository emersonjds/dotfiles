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
  exit 0
fi

os="$(detect_os)"
log "Detected OS: $os"

case "$os" in
  macos)                 bash "$SCRIPT_DIR/macos/setup.sh" ;;
  debian|fedora|arch)    bash "$SCRIPT_DIR/linux/setup.sh" ;;
  *) err "Unsupported OS. Supported: macOS, Debian/Ubuntu/Mint, Fedora, Arch."; exit 1 ;;
esac

run_common_stage

log "Done. Open a new terminal (or run: exec zsh)."
