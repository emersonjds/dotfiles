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

# Package lists never shrink: an app missing from one machine must not drop it from the repo.
merge_list() {
  local file="$1" tmp
  tmp="$(mktemp)"
  { cat - ; cat "$file" 2>/dev/null; } | grep -vE '^[[:space:]]*$' | sort -u > "$tmp"
  if cmp -s "$tmp" "$file"; then
    rm -f "$tmp"
  else
    mv "$tmp" "$file"
    log "updated: ${file#"$DOTFILES_DIR"/}"
    changed=$((changed + 1))
  fi
}

if command_exists brew; then
  if [ "$(uname -s)" = "Darwin" ]; then
    brewfile="$DOTFILES_DIR/macos/Brewfile"
    tmp="$(mktemp)"
    { sed -n '/^[^#]/q;p' "$brewfile"
      brew bundle dump --file=- --no-vscode --no-npm --no-cargo --no-uv 2>/dev/null
    } > "$tmp"
    if cmp -s "$tmp" "$brewfile"; then
      rm -f "$tmp"
    else
      mv "$tmp" "$brewfile"
      log "updated: macos/Brewfile"
      changed=$((changed + 1))
    fi
  fi
  merge_list "$DOTFILES_DIR/packages/vscode-extensions.txt" < <(
    brew bundle dump --file=- --no-formula --no-cask --no-tap --no-mas --vscode 2>/dev/null \
      | sed -E 's/^vscode "([^"]+)".*/\1/')
  merge_list "$DOTFILES_DIR/packages/npm-global.txt" < <(
    brew bundle dump --file=- --no-formula --no-cask --no-tap --no-mas --npm 2>/dev/null \
      | sed -E 's/^npm "([^"]+)".*/\1/' | grep -vE '^(npm|corepack)$')
fi

if [ "$changed" -eq 0 ]; then
  log "Nothing changed: repo already matches the machine."
else
  log "$changed file(s) updated. Review with: git diff"
fi
