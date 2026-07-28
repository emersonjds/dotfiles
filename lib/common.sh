#!/usr/bin/env bash
# Helpers compartilhados pelos instaladores. Source, não execute.

# Raiz do repo (lib/ está um nível abaixo da raiz).
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIR

# Fragmentos de shell vivem aqui, fora do repo — apagar o repo não quebra o shell.
SHELL_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
export SHELL_CONFIG_DIR

_c_reset=$'\033[0m'; _c_blue=$'\033[34m'; _c_yellow=$'\033[33m'; _c_red=$'\033[31m'
log()  { printf '%s==>%s %s\n' "$_c_blue" "$_c_reset" "$*"; }
warn() { printf '%s[!]%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
err()  { printf '%s[x]%s %s\n' "$_c_red" "$_c_reset" "$*" >&2; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# macos | debian | fedora | arch | unknown. ID_LIKE catches the derivatives
# (Mint, Pop!_OS, Manjaro, Rocky) without listing every one of them.
detect_os() {
  [ "$(uname -s)" = "Darwin" ] && { echo macos; return 0; }
  [ "$(uname -s)" = "Linux" ] || { echo unknown; return 0; }
  [ -r /etc/os-release ] || { echo unknown; return 0; }
  local id id_like
  id="$(. /etc/os-release && echo "${ID:-}")"
  id_like="$(. /etc/os-release && echo "${ID_LIKE:-}")"
  case "$id $id_like" in
    *debian*|*ubuntu*|*linuxmint*) echo debian ;;
    *fedora*|*rhel*|*centos*)      echo fedora ;;
    *arch*)                        echo arch ;;
    *) echo unknown ;;
  esac
}

brew_prefix() {
  if command_exists brew; then
    brew --prefix
  elif [ -d /opt/homebrew ]; then
    echo /opt/homebrew
  else
    echo /home/linuxbrew/.linuxbrew
  fi
}

# Mapa único "caminho-no-repo|destino-na-máquina".
# Fonte de verdade do install.sh (repo -> máquina) e do sync.sh (máquina -> repo).
dotfiles_map() {
  local xdg="${XDG_CONFIG_HOME:-$HOME/.config}"
  cat <<EOF
shell/zshrc|$HOME/.zshrc
shell/zprofile|$HOME/.zprofile
shell/env.sh|$SHELL_CONFIG_DIR/env.sh
shell/aliases.sh|$SHELL_CONFIG_DIR/aliases.sh
shell/plugins.sh|$SHELL_CONFIG_DIR/plugins.sh
git/gitconfig|$HOME/.gitconfig
config/starship.toml|$xdg/starship.toml
config/zed/settings.json|$xdg/zed/settings.json
EOF
  if [ "$(uname -s)" = "Darwin" ]; then
    cat <<EOF
config/iterm2/emerson.json|$HOME/Library/Application Support/iTerm2/DynamicProfiles/emerson.json
config/vscode/settings.json|$HOME/Library/Application Support/Code/User/settings.json
EOF
  else
    echo "config/vscode/settings.json|$xdg/Code/User/settings.json"
  fi
}

# Copia src -> dest, com backup timestampado do que já existia.
# Symlink no destino é resquício do modelo antigo (apontava pro repo): descarta.
install_file() {
  local src="$1" dest="$2"
  [ -r "$src" ] || { warn "origem ausente, pulei: $src"; return 0; }
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    warn "symlink legado removido: $dest"
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    cmp -s "$src" "$dest" && return 0
    local stamp; stamp="$(date +%Y%m%d%H%M%S)"
    warn "backup: $dest -> $dest.bak.$stamp"
    cp -p "$dest" "$dest.bak.$stamp"
  fi
  cp -f "$src" "$dest"
  log "copiado: $dest"
}
