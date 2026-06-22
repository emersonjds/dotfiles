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

# Taps de terceiros (supabase, ngrok) exigem "trust" no Homebrew atual.
# `brew trust` não é confiável entre versões; desligar a checagem garante
# que o `brew bundle` não quebre no meio por causa das taps.
log "Confiando nas taps de terceiros"
brew tap supabase/tap >/dev/null 2>&1 || true
brew tap ngrok/ngrok  >/dev/null 2>&1 || true
export HOMEBREW_NO_REQUIRE_TAP_TRUST=1

# Não engolir falhas: se algum cask/formula falhar, mostramos exatamente o quê
# (antes isso ficava mascarado e apps como o Obsidian sumiam silenciosamente).
log "brew bundle (formulae + casks + fonts)"
if ! brew bundle --file="$SCRIPT_DIR/Brewfile"; then
  warn "brew bundle terminou com falhas — itens que NÃO ficaram instalados:"
  brew bundle check --file="$SCRIPT_DIR/Brewfile" --verbose || true
  warn "Reveja os itens acima e rode novamente: brew bundle --file=$SCRIPT_DIR/Brewfile"
fi

log "brew cleanup"
brew cleanup || true
