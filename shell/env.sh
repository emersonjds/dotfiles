#!/usr/bin/env bash
# Cross-platform environment. Sourced by ~/.zshrc and by ~/.bashrc.
# Everything resolves at runtime: no hardcoded versions, no machine-specific paths.
#
# rbenv and pyenv generate shell-specific init code, so the shell has to be named rather
# than assumed. Getting this wrong is quiet: `rbenv init - zsh` evaluated by bash defines
# nothing usable and reports no error.
_shell_name="zsh"
[ -n "${BASH_VERSION:-}" ] && _shell_name="bash"

# Keeps PATH from growing on every re-source.
path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) return 0 ;; esac
  PATH="$1:$PATH"
}

# Optional per-machine overrides (e.g. JAVA_VERSION=21). Not versioned.
_shell_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
# shellcheck disable=SC1091
[ -r "$_shell_config_dir/versions.env" ] && . "$_shell_config_dir/versions.env"
# 17 is the version Android, React Native and Flutter all agree on.
JAVA_VERSION="${JAVA_VERSION:-17}"

_os="$(uname -s)"

# Homebrew belongs in ~/.zprofile; this is the fallback for non-login shells. Both go
# through the same file, so the list of prefixes exists in exactly one place.
# shellcheck disable=SC1091
[ -r "$_shell_config_dir/brew.sh" ] && . "$_shell_config_dir/brew.sh"

if [ "$_os" = "Darwin" ]; then
  JAVA_HOME="$(/usr/libexec/java_home -v "$JAVA_VERSION" 2>/dev/null)"
  [ -z "$JAVA_HOME" ] && JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)"
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export PNPM_HOME="$HOME/Library/pnpm"
else
  if command -v brew >/dev/null 2>&1 && [ -d "$(brew --prefix "openjdk@${JAVA_VERSION}" 2>/dev/null)" ]; then
    JAVA_HOME="$(brew --prefix "openjdk@${JAVA_VERSION}")"
  elif [ -d "/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64" ]; then
    JAVA_HOME="/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64"
  elif command -v brew >/dev/null 2>&1 && [ -d "$(brew --prefix openjdk 2>/dev/null)" ]; then
    JAVA_HOME="$(brew --prefix openjdk)"
  elif [ -d /usr/lib/jvm/default-java ]; then
    JAVA_HOME=/usr/lib/jvm/default-java
  fi
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi

[ -n "${JAVA_HOME:-}" ] && export JAVA_HOME && path_prepend "$JAVA_HOME/bin"

export ANDROID_SDK_ROOT="$ANDROID_HOME"
path_prepend "$ANDROID_HOME/emulator"
path_prepend "$ANDROID_HOME/platform-tools"
path_prepend "$ANDROID_HOME/cmdline-tools/latest/bin"

# The macOS cask links flutter into brew's bin; on Linux it is an upstream tarball.
# path_prepend ignores the one that isn't there.
path_prepend "$HOME/development/flutter/bin"
path_prepend "$HOME/.pub-cache/bin"

# postgresql is keg-only, so brew never links psql onto PATH. Pick the newest installed
# version rather than whichever one the glob happens to return last.
if [ -n "${HOMEBREW_PREFIX:-}" ]; then
  _pg_best=0
  for _pg in "$HOMEBREW_PREFIX"/opt/postgresql@*/bin; do
    [ -d "$_pg" ] || continue
    _pg_v="${_pg%/bin}"; _pg_v="${_pg_v##*postgresql@}"; _pg_v="${_pg_v%%.*}"
    case "$_pg_v" in ''|*[!0-9]*) continue ;; esac
    [ "$_pg_v" -gt "$_pg_best" ] && { _pg_best="$_pg_v"; _pg_dir="$_pg"; }
  done
  [ -n "${_pg_dir:-}" ] && path_prepend "$_pg_dir"
  unset _pg _pg_v _pg_best _pg_dir
fi

# nvm.sh and its completions are loaded late, from ~/.zshrc.
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
path_prepend "$PNPM_HOME"
path_prepend "$HOME/.yarn/bin"
path_prepend "${XDG_CONFIG_HOME:-$HOME/.config}/yarn/global/node_modules/.bin"

# rbenv (CocoaPods). `rbenv init` adds the shims itself, so don't prepend them here.
# RBENV_SHELL is set by it and doubles as the already-initialised guard.
if command -v rbenv >/dev/null 2>&1 && [ -z "${RBENV_SHELL:-}" ]; then
  export RBENV_ROOT="${RBENV_ROOT:-$HOME/.rbenv}"
  path_prepend "$RBENV_ROOT/bin"
  eval "$(rbenv init - "$_shell_name")"
fi

# rustup writes this env file; a brew install only leaves ~/.cargo/bin.
# shellcheck disable=SC1091
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
path_prepend "$HOME/.cargo/bin"

# pyenv only when actually installed: it shadows brew's python otherwise.
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  path_prepend "$PYENV_ROOT/bin"
  eval "$(pyenv init - "$_shell_name")"
fi

path_prepend "$HOME/.local/share/solana/install/active_release/bin"
path_prepend "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
path_prepend "$HOME/.local/share/JetBrains/Toolbox/scripts"

export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export REACT_NATIVE_NO_METRO_WINDOW=true

# Last, so it wins: home of claude, uv and every pipx binary.
path_prepend "$HOME/.local/bin"
export PATH
unset _os _shell_config_dir _shell_name
