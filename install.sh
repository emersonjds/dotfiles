#!/usr/bin/env bash
# Setup de uma máquina nova — macOS ou Linux (Ubuntu/Debian/Mint).
# Uso: ./install.sh                 instala pacotes + configs
#      ./install.sh --configs-only  só recopia as configs (rápido, sem tocar em pacotes)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/stage_common.sh"

log "Dotfiles — repo: $DOTFILES_DIR"

if [ "${1:-}" = "--configs-only" ]; then
  install_configs
  log "Configs aplicadas. Abra um novo terminal (ou rode: exec zsh)."
  exit 0
fi

os="$(detect_os)"
log "SO detectado: $os"

case "$os" in
  macos)  bash "$SCRIPT_DIR/macos/setup.sh" ;;
  debian) bash "$SCRIPT_DIR/linux/setup.sh" ;;
  *) err "SO não suportado. Suportados: macOS, Ubuntu/Debian/Mint."; exit 1 ;;
esac

# Estágio comum (configs, SDKs, shell)
run_common_stage

log "Tudo pronto! Abra um novo terminal (ou rode: exec zsh)."
