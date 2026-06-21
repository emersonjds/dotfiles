#!/usr/bin/env bash
# Inicialização de plugins. Probe de múltiplos caminhos (brew mac/linux + apt).

_zsh_share=""
if command -v brew >/dev/null 2>&1; then _zsh_share="$(brew --prefix)/share"; fi

_source_first() {
  # Tenta cada caminho; usa o primeiro que existir.
  for p in "$@"; do
    if [ -r "$p" ]; then . "$p"; return 0; fi
  done
  return 1
}

# autosuggestions (sugestão cinza do histórico)
_source_first \
  "$_zsh_share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# zoxide (cd inteligente: `z parte-do-nome`)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# fzf (Ctrl-R histórico, Ctrl-T arquivos)
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh) 2>/dev/null

# starship (prompt) — substitui tema do Oh My Zsh
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# syntax-highlighting — PRECISA ser o último a carregar
_source_first \
  "$_zsh_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
