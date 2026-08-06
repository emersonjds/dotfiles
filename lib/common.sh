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
ok()   { printf '  %s✓%s %s\n' "$_c_blue" "$_c_reset" "$*"; }

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

# What detect_os() returns is a package-manager family, not a distro: every apt system
# answers "debian" because they all take the same code path. That is the right thing to
# branch on and a terrible thing to print — on Mint, "Detected OS: debian" reads like a
# misdetection. This is the human-facing name, for logs only.
os_description() {
  if [ "$(uname -s)" = "Darwin" ]; then
    printf 'macOS %s (%s)\n' "$(sw_vers -productVersion 2>/dev/null || echo '?')" "$(uname -m)"
    return 0
  fi
  [ -r /etc/os-release ] || { uname -sr; return 0; }
  local pretty codename base
  pretty="$(. /etc/os-release && echo "${PRETTY_NAME:-${NAME:-Linux}}")"
  codename="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"
  base="$(ubuntu_codename 2>/dev/null || true)"
  # Mint names its own release (zena) and rides an Ubuntu one (noble). Both matter: the
  # first is what the user sees, the second is what third-party apt repos are keyed on.
  if [ -n "$base" ] && [ "$base" != "$codename" ]; then
    printf '%s [%s, on Ubuntu %s]\n' "$pretty" "${codename:-?}" "$base"
  elif [ -n "$codename" ]; then
    printf '%s [%s]\n' "$pretty" "$codename"
  else
    printf '%s\n' "$pretty"
  fi
}

# Mint reports its own codename (zena) and a Debian version (trixie/sid) that has
# nothing to do with its actual base. Third-party apt repos are keyed on the Ubuntu
# codename, so resolve that: UBUNTU_CODENAME on the derivatives, VERSION_CODENAME on
# Ubuntu itself.
ubuntu_codename() {
  [ -r /etc/os-release ] || return 1
  local c
  c="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")"
  [ -n "$c" ] || return 1
  echo "$c"
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

# Puts an already-installed Homebrew on PATH, and says whether it found one.
#
# The setup scripts run as non-interactive subprocesses: no rc file has run, so nothing has
# put brew on PATH for them. Asking `command_exists brew` first therefore answers "no" on a
# machine that has had Homebrew for months, and the installer runs again from scratch —
# which is where "Warning: /home/linuxbrew/.linuxbrew/bin is not in your PATH" comes from.
# Call this before deciding whether to install.
load_brew() {
  command_exists brew && return 0
  local b; b="$(brew_prefix)/bin/brew"
  [ -x "$b" ] || return 1
  eval "$("$b" shellenv)"
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
shell/brew.sh|$SHELL_CONFIG_DIR/brew.sh
shell/env.sh|$SHELL_CONFIG_DIR/env.sh
shell/aliases.sh|$SHELL_CONFIG_DIR/aliases.sh
shell/plugins.sh|$SHELL_CONFIG_DIR/plugins.sh
git/gitconfig|$HOME/.gitconfig
config/starship.toml|$xdg/starship.toml
config/zed/settings.json|$xdg/zed/settings.json
config/ghostty/config|$xdg/ghostty/config
EOF
  if [ "$(uname -s)" = "Darwin" ]; then
    cat <<EOF
config/iterm2/emerson.json|$HOME/Library/Application Support/iTerm2/DynamicProfiles/emerson.json
config/vscode/settings.json|$HOME/Library/Application Support/Code/User/settings.json
EOF
  else
    echo "config/vscode/settings.json|$xdg/Code/User/settings.json"
    # X11-only: macOS has no Compose layer to correct.
    echo "config/XCompose|$HOME/.XCompose"
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
