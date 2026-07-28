#!/usr/bin/env bash
# Plugin init. Paths differ between brew (macOS/Linux) and apt, so each one is probed.

_zsh_share=""
if command -v brew >/dev/null 2>&1; then _zsh_share="$(brew --prefix)/share"; fi

_source_first() {
  for p in "$@"; do
    if [ -r "$p" ]; then . "$p"; return 0; fi
  done
  return 1
}

_source_first \
  "$_zsh_share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh) 2>/dev/null
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# syntax-highlighting MUST be sourced last.
_source_first \
  "$_zsh_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
