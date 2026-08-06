#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

log "Command Line Tools"
xcode-select -p >/dev/null 2>&1 || xcode-select --install || true

if load_brew; then
  log "Homebrew: already installed ($(brew --prefix))"
else
  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew || { err "Homebrew install failed"; exit 1; }
fi

log "brew update"
brew update

# Only installs what is missing; third-party taps are trusted in the Brewfile itself.
log "brew bundle"
brew bundle --file="$SCRIPT_DIR/Brewfile" || warn "brew bundle had failures (continuing)"

log "brew upgrade"
brew upgrade || warn "brew upgrade had failures (continuing)"

brew cleanup || true
