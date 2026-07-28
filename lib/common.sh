#!/usr/bin/env bash
# Shared helpers. Source this, don't execute it.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_DIR

# Shell fragments live outside the repo, so deleting the repo can't break the shell.
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

vscode_cli() {
  local c
  for c in code code-insiders; do
    command_exists "$c" && { echo "$c"; return 0; }
  done
  for c in "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
           "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"; do
    [ -x "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}

# Single "repo-path|machine-path" map: source of truth for install.sh and sync.sh.
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

# A symlink at dest is a leftover of the old model (it pointed into the repo): drop it.
install_file() {
  local src="$1" dest="$2"
  [ -r "$src" ] || { warn "missing source, skipped: $src"; return 0; }
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    warn "removed legacy symlink: $dest"
    rm -f "$dest"
  elif [ -e "$dest" ]; then
    cmp -s "$src" "$dest" && return 0
    local stamp; stamp="$(date +%Y%m%d%H%M%S)"
    warn "backup: $dest -> $dest.bak.$stamp"
    cp -p "$dest" "$dest.bak.$stamp"
    # One backup is a safety net; a pile of them is clutter. Keep only the newest.
    find "$(dirname "$dest")" -maxdepth 1 -name "$(basename "$dest").bak.*" \
      ! -name "*.bak.$stamp" -delete 2>/dev/null || true
  fi
  cp -f "$src" "$dest"
  log "copied: $dest"
}
