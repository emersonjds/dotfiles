#!/usr/bin/env bash
# Setup de uma máquina nova — macOS ou Linux (Ubuntu/Debian/Mint).
# Uso: git clone <repo> ~/dotfiles && cd ~/dotfiles && ./install.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log "Dotfiles — repo: $DOTFILES_DIR"
os="$(detect_os)"
log "SO detectado: $os"

case "$os" in
  macos)  bash "$SCRIPT_DIR/macos/setup.sh" ;;
  debian) bash "$SCRIPT_DIR/linux/setup.sh" ;;
  *) err "SO não suportado. Suportados: macOS, Ubuntu/Debian/Mint."; exit 1 ;;
esac

# Estágio comum (symlinks, SDKs, shell)
source "$SCRIPT_DIR/lib/stage_common.sh"
run_common_stage

log "Tudo pronto! Abra um novo terminal (ou rode: exec zsh)."
