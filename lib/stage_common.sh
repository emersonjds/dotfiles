#!/usr/bin/env bash
# Estágio comum aos dois SOs. Source após lib/common.sh.

link_dotfiles() {
  log "Linkando dotfiles"
  safe_symlink "$DOTFILES_DIR/shell/zshrc"              "$HOME/.zshrc"
  safe_symlink "$DOTFILES_DIR/git/gitconfig"            "$HOME/.gitconfig"
  safe_symlink "$DOTFILES_DIR/config/starship.toml"     "$HOME/.config/starship.toml"
  safe_symlink "$DOTFILES_DIR/config/zed/settings.json" "$HOME/.config/zed/settings.json"
  # O zshrc resolve a raiz do repo pelo próprio symlink, então não dependemos de ~/dotfiles.
}

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Instalando Oh My Zsh"
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

install_node() {
  export NVM_DIR="$HOME/.nvm"
  [ -d "$NVM_DIR" ] || mkdir -p "$NVM_DIR"
  # shellcheck disable=SC1091
  [ -s "$(brew_prefix)/opt/nvm/nvm.sh" ] && . "$(brew_prefix)/opt/nvm/nvm.sh"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  if command_exists nvm; then
    log "Instalando Node LTS (latest)"
    nvm install --lts
    nvm alias default 'lts/*'
  else
    warn "nvm indisponível; pulei Node"
  fi
}

install_bun() {
  command_exists bun && return 0
  log "Instalando Bun (latest)"
  curl -fsSL https://bun.sh/install | bash || warn "falha ao instalar bun"
}

install_npm_globals() {
  command_exists npm || { warn "npm ausente; pulei globals"; return 0; }
  log "Instalando npm globals"
  while read -r pkg; do
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    npm ls -g "$pkg" >/dev/null 2>&1 || npm install -g "$pkg"
  done < "$DOTFILES_DIR/packages/npm-global.txt"
}

install_vscode_exts() {
  command_exists code || { warn "code CLI ausente; pulei extensões"; return 0; }
  log "Instalando extensões VSCode"
  while read -r ext; do
    [ -z "$ext" ] && continue
    case "$ext" in \#*) continue ;; esac
    code --install-extension "$ext" --force >/dev/null 2>&1 || warn "falhou: $ext"
  done < "$DOTFILES_DIR/packages/vscode-extensions.txt"
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
  link_dotfiles
  install_node
  install_bun
  install_npm_globals
  install_vscode_exts
  install_ai_clis
  set_default_shell
  log "Estágio comum concluído"
}
