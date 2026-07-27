#!/usr/bin/env bash
# Variáveis de ambiente cross-platform. Sourced pelo ~/.zshrc.
# Resolve tudo dinamicamente — nada de versão hardcoded, nada de caminho de uma máquina só.

# Adiciona ao PATH só se o diretório existe e ainda não está lá.
# Sem isso o PATH duplicava a cada `source`.
path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) return 0 ;; esac
  PATH="$1:$PATH"
}

# Override opcional de versões (ex.: JAVA_VERSION=21), local da máquina e não-versionado.
_shell_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/shell"
# shellcheck disable=SC1091
[ -r "$_shell_config_dir/versions.env" ] && . "$_shell_config_dir/versions.env"
# Java padrão: 17 (estável p/ Android/React Native/Flutter).
# Quando o latest estiver de boa com RN/Flutter, troque o 17 aqui (ou via versions.env).
JAVA_VERSION="${JAVA_VERSION:-17}"

_os="$(uname -s)"

# Homebrew mora no ~/.zprofile (login shell). Aqui é só rede de segurança
# para shell não-login — o guard evita duplicar PATH.
if ! command -v brew >/dev/null 2>&1; then
  for _b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [ -x "$_b" ] && { eval "$("$_b" shellenv)"; break; }
  done
  unset _b
fi

if [ "$_os" = "Darwin" ]; then
  # Java: usa a versão pedida (padrão 17); se não existir, cai pra mais nova instalada
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

# Android SDK
export ANDROID_SDK_ROOT="$ANDROID_HOME"
path_prepend "$ANDROID_HOME/emulator"
path_prepend "$ANDROID_HOME/platform-tools"
path_prepend "$ANDROID_HOME/cmdline-tools/latest/bin"

# Node: nvm, pnpm, yarn, bun (nvm.sh e completions são carregados no ~/.zshrc)
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
path_prepend "$PNPM_HOME"
path_prepend "$HOME/.yarn/bin"
path_prepend "${XDG_CONFIG_HOME:-$HOME/.config}/yarn/global/node_modules/.bin"

# Ruby: rbenv (usado pelo CocoaPods). Sem isso o rbenv fica instalado e inerte.
if command -v rbenv >/dev/null 2>&1; then
  export RBENV_ROOT="${RBENV_ROOT:-$HOME/.rbenv}"
  path_prepend "$RBENV_ROOT/bin"
  path_prepend "$RBENV_ROOT/shims"
  eval "$(rbenv init - zsh)"
fi

# Rust: rustup escreve o env.; via brew só existe o ~/.cargo/bin.
# shellcheck disable=SC1091
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
path_prepend "$HOME/.cargo/bin"

# Python: pipx e uv instalam em ~/.local/bin (prependado no fim do arquivo).
# pyenv só se estiver de fato instalado — no brew python o pyenv atrapalha.
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  path_prepend "$PYENV_ROOT/bin"
  eval "$(pyenv init - zsh)"
fi

# Solana e JetBrains Toolbox: estavam chumbados no ~/.zprofile, fora do repo.
# path_prepend já ignora se o diretório não existir.
path_prepend "$HOME/.local/share/solana/install/active_release/bin"
path_prepend "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
path_prepend "$HOME/.local/share/JetBrains/Toolbox/scripts"

export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export REACT_NATIVE_NO_METRO_WINDOW=true

# Por último: ~/.local/bin ganha prioridade. É onde vivem claude, uv e os
# binários do pipx — deixar de fora foi o que sumiu com o Claude Code.
path_prepend "$HOME/.local/bin"
export PATH
unset _os _shell_config_dir
