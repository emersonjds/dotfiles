#!/usr/bin/env bash
# Estágio comum aos dois SOs. Source após lib/common.sh.

# Old-model symlinks pointed into the repo and turned into dangling files once it moved.
# Backing one up produced a *.bak.* that is itself a symlink into the repo: drop those too.
clean_legacy_links() {
  local n=0 dest f
  while IFS='|' read -r _ dest; do
    [ -n "$dest" ] || continue
    while IFS= read -r f; do
      rm -f "$f"; n=$((n + 1))
    done < <(find "$(dirname "$dest")" -maxdepth 1 -type l \
               -name "$(basename "$dest").bak.*" 2>/dev/null)
  done < <(dotfiles_map)
  [ "$n" -gt 0 ] && log "removed $n legacy symlink backups"
  return 0
}

read_list() {
  grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || true
}

install_configs() {
  log "Configs (copied to the machine)"
  clean_legacy_links
  mkdir -p "$SHELL_CONFIG_DIR"
  while IFS='|' read -r rel dest; do
    [ -n "$rel" ] || continue
    install_file "$DOTFILES_DIR/$rel" "$dest"
  done < <(dotfiles_map)
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh: updating"
    ZSH="$HOME/.oh-my-zsh" sh "$HOME/.oh-my-zsh/tools/upgrade.sh" >/dev/null 2>&1 \
      || warn "oh-my-zsh update failed"
    return 0
  fi
  log "Oh My Zsh: installing"
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_node() {
  export NVM_DIR="$HOME/.nvm"
  [ -d "$NVM_DIR" ] || mkdir -p "$NVM_DIR"
  # shellcheck disable=SC1091
  [ -s "$(brew_prefix)/opt/nvm/nvm.sh" ] && . "$(brew_prefix)/opt/nvm/nvm.sh"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  command_exists nvm || { warn "nvm unavailable; skipped Node"; return 0; }
  log "Node: latest LTS"
  nvm install --lts
  nvm alias default 'lts/*' >/dev/null
}

# Without a version installed, rbenv sits there inert and `ruby` silently falls back
# to the system copy.
install_ruby() {
  command_exists rbenv || { warn "rbenv missing; skipped Ruby"; return 0; }
  if [ -n "$(rbenv versions --bare 2>/dev/null)" ]; then
    log "Ruby: $(rbenv global 2>/dev/null) already installed"
    return 0
  fi
  local latest
  latest="$(rbenv install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)"
  [ -n "$latest" ] || { warn "could not resolve a Ruby version; skipped"; return 0; }
  log "Ruby: installing $latest (compiles, takes a few minutes)"
  rbenv install -s "$latest" || { warn "ruby $latest failed to build"; return 0; }
  rbenv global "$latest"
  rbenv rehash
}

install_bun() {
  if command_exists bun; then
    log "Bun: updating"
    bun upgrade >/dev/null 2>&1 || warn "bun upgrade failed"
    return 0
  fi
  log "Bun: installing"
  curl -fsSL https://bun.sh/install | bash || warn "bun install failed"
}

install_npm_globals() {
  command_exists npm || { warn "npm missing; skipped globals"; return 0; }
  local pkg
  log "npm globals"
  while read -r pkg; do
    npm install -g "$pkg@latest" >/dev/null 2>&1 </dev/null || warn "npm failed: $pkg"
  done < <(read_list "$DOTFILES_DIR/packages/npm-global.txt")
}

install_vscode_exts() {
  local cli ext
  cli="$(vscode_cli)" || { warn "VS Code CLI missing; skipped extensions"; return 0; }
  log "VS Code extensions"
  while read -r ext; do
    "$cli" --install-extension "$ext" --force >/dev/null 2>&1 </dev/null \
      || warn "extension failed: $ext"
  done < <(read_list "$DOTFILES_DIR/packages/vscode-extensions.txt")
}

install_ai_clis() {
  # Claude Code + Copilot CLI já vêm via npm-global.txt. Aqui: extensão gh copilot.
  if command_exists gh; then
    if ! gh extension list 2>/dev/null | grep -q 'github/gh-copilot'; then
      log "Instalando extensão gh copilot"
      gh extension install github/gh-copilot >/dev/null 2>&1 || warn "gh copilot falhou (faça gh auth login antes)"
    fi
  else
    warn "gh ausente; pulei extensão copilot"
  fi
}

set_default_shell() {
  local zsh_bin; zsh_bin="$(command -v zsh)"
  [ -z "$zsh_bin" ] && return 0
  if [ "${SHELL:-}" != "$zsh_bin" ]; then
    log "Definindo zsh como shell padrão (pode pedir senha)"
    grep -qx "$zsh_bin" /etc/shells 2>/dev/null || \
      echo "$zsh_bin" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$zsh_bin" || warn "chsh falhou; troque manualmente"
  fi
}

run_common_stage() {
  install_oh_my_zsh
  install_configs
  install_node
  install_bun
  install_npm_globals
  install_vscode_exts
  install_ai_clis
  set_default_shell
  log "Estágio comum concluído"
}
