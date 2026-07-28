#!/usr/bin/env bash
# Machine -> repo. Installs are copies, so the repo is not the live source: this reconciles it.
# Usage: ./sync.sh   (then review with `git diff` and commit)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

log "Syncing machine -> repo: $DOTFILES_DIR"

changed=0
while IFS='|' read -r rel dest; do
  [ -n "$rel" ] || continue
  if [ ! -r "$dest" ]; then
    warn "not on this machine, skipped: $dest"
    continue
  fi
  cmp -s "$dest" "$DOTFILES_DIR/$rel" && continue
  cp -f "$dest" "$DOTFILES_DIR/$rel"
  log "updated: $rel"
  changed=$((changed + 1))
done < <(dotfiles_map)

if [ "$changed" -eq 0 ]; then
  log "Nothing changed: repo already matches the machine."
else
  log "$changed file(s) updated. Review with: git diff"
fi
