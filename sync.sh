#!/usr/bin/env bash
# Caminho de volta: traz pro repo as configs editadas direto na máquina.
# Como a instalação é por cópia, o repo não é mais a fonte viva — isso reconcilia.
# Uso: ./sync.sh   (depois confira com `git diff` e commite)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log "Sincronizando máquina -> repo: $DOTFILES_DIR"

changed=0
while IFS='|' read -r rel dest; do
  [ -n "$rel" ] || continue
  if [ ! -r "$dest" ]; then
    warn "não existe na máquina, pulei: $dest"
    continue
  fi
  cmp -s "$dest" "$DOTFILES_DIR/$rel" && continue
  cp -f "$dest" "$DOTFILES_DIR/$rel"
  log "atualizado: $rel"
  changed=$((changed + 1))
done < <(dotfiles_map)

if [ "$changed" -eq 0 ]; then
  log "Nada mudou — repo já está igual à máquina."
else
  log "$changed arquivo(s) atualizado(s). Revise com: git diff"
fi
