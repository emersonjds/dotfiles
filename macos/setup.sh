#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

log "macOS: instalando Command Line Tools (se faltar)"
xcode-select -p >/dev/null 2>&1 || xcode-select --install || true

if ! command_exists brew; then
  log "Instalando Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$(brew_prefix)/bin/brew" shellenv)"

log "brew update"
brew update

log "brew bundle (formulae + casks + fonts)"
brew bundle --file="$SCRIPT_DIR/Brewfile" || warn "brew bundle teve falhas pontuais (continuando)"

log "brew cleanup"
brew cleanup || true
