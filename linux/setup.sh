#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

log "apt: base do sistema"
sudo apt-get update -y
sudo apt-get install -y \
  build-essential curl wget git file procps ca-certificates gnupg \
  zsh flatpak fontconfig unzip

# Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# Homebrew-on-Linux (mesmas CLIs do Mac)
if ! command_exists brew; then
  log "Instalando Homebrew-on-Linux"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew update

# Instala SÓ as formulae do Brewfile (casks não existem no Linux)
log "brew: CLIs/SDKs do Brewfile (formulae)"
grep -E '^brew ' "$SCRIPT_DIR/../macos/Brewfile" \
  | sed -E 's/^brew "([^"]+)".*/\1/' \
  | grep -vE '^(cocoapods|mas)$' \
  | while read -r f; do brew list "$f" >/dev/null 2>&1 || brew install "$f" || warn "brew falhou: $f"; done

# GUI nativos via repositórios oficiais
install_chrome() {
  command_exists google-chrome && return 0
  log "Chrome"
  wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt-get install -y /tmp/chrome.deb
}
install_vscode() {
  command_exists code && return 0
  log "VSCode"
  wget -qO /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  sudo apt-get install -y /tmp/vscode.deb
}
install_chrome || warn "Chrome falhou"
install_vscode || warn "VSCode falhou"

# GUI via Flatpak
log "Flatpak: apps GUI"
for app in \
  dev.zed.Zed \
  io.dbeaver.DBeaverCommunity \
  com.usebruno.Bruno \
  md.obsidian.Obsidian \
  com.discordapp.Discord \
  com.mongodb.Compass \
  org.libreoffice.LibreOffice ; do
  flatpak install -y --noninteractive flathub "$app" || warn "flatpak falhou: $app"
done

# PWAs (WhatsApp, Notion, Outlook) — atalhos .desktop usando Chrome --app
log "Criando PWAs (WhatsApp, Notion, Outlook)"
mkdir -p "$HOME/.local/share/applications"
make_pwa() { # nome, url, arquivo
  cat > "$HOME/.local/share/applications/$3.desktop" <<EOF
[Desktop Entry]
Name=$1
Exec=google-chrome --app=$2
Type=Application
Icon=google-chrome
Categories=Network;
EOF
}
make_pwa "WhatsApp" "https://web.whatsapp.com"   "whatsapp-pwa"
make_pwa "Notion"   "https://www.notion.so"      "notion-pwa"
make_pwa "Outlook"  "https://outlook.office.com" "outlook-pwa"

log "Linux: instalação de pacotes concluída"
