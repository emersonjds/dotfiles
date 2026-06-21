#!/usr/bin/env bash
# Helpers compartilhados pelos instaladores. Source, não execute.

# Raiz do repo (lib/ está um nível abaixo da raiz).
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIR

_c_reset=$'\033[0m'; _c_blue=$'\033[34m'; _c_yellow=$'\033[33m'; _c_red=$'\033[31m'
log()  { printf '%s==>%s %s\n' "$_c_blue" "$_c_reset" "$*"; }
warn() { printf '%s[!]%s %s\n' "$_c_yellow" "$_c_reset" "$*" >&2; }
err()  { printf '%s[x]%s %s\n' "$_c_red" "$_c_reset" "$*" >&2; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      if [ -r /etc/os-release ] && grep -qiE 'debian|ubuntu|mint' /etc/os-release; then
        echo debian
      else
        echo unknown
      fi
      ;;
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

safe_symlink() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return 0
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local stamp; stamp="$(date +%Y%m%d%H%M%S)"
    warn "backup: $dest -> $dest.bak.$stamp"
    mv "$dest" "$dest.bak.$stamp"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  log "link: $dest -> $src"
}
