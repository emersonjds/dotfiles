#!/usr/bin/env bash
# Variáveis de ambiente cross-platform. Sourced pelo ~/.zshrc.
# Resolve tudo dinamicamente — nada de versão hardcoded.

# Override opcional de versões (ex.: JAVA_VERSION=21). Não-versionado.
[ -r "${DOTFILES:-$HOME/dotfiles}/packages/versions.env" ] && . "${DOTFILES:-$HOME/dotfiles}/packages/versions.env"
# Java padrão: 17 (estável p/ Android/React Native/Flutter).
# Quando o latest estiver de boa com RN/Flutter, troque o 17 aqui (ou via versions.env).
JAVA_VERSION="${JAVA_VERSION:-17}"

_os="$(uname -s)"

if [ "$_os" = "Darwin" ]; then
  # Homebrew (Apple Silicon ou Intel)
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
  # Java: usa a versão pedida (padrão 17); se não existir, cai pra mais nova instalada
  JAVA_HOME="$(/usr/libexec/java_home -v "$JAVA_VERSION" 2>/dev/null)"
  [ -z "$JAVA_HOME" ] && JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)"
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export PNPM_HOME="$HOME/Library/pnpm"
else
  # Linux: Homebrew-on-Linux
  if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
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

[ -n "${JAVA_HOME:-}" ] && export JAVA_HOME && export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export REACT_NATIVE_NO_METRO_WINDOW=true

# PATH: Android, bun, pnpm, local bin
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac
export PATH="$HOME/.local/bin:$PATH"
