#!/usr/bin/env bash
# Debian/Ubuntu/Mint, Fedora and Arch. Only the system base and the GUI apps are
# distro-specific: every CLI comes from Homebrew on Linux, which is distro-agnostic.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

distro="$(detect_os)"
log "Linux flavour: $distro"

install_base() {
  case "$distro" in
    debian)
      sudo apt-get update -y
      sudo apt-get install -y \
        build-essential curl wget git file procps ca-certificates gnupg \
        zsh flatpak fontconfig unzip
      ;;
    fedora)
      sudo dnf install -y --skip-unavailable \
        @development-tools curl wget git file procps-ng ca-certificates gnupg2 \
        zsh flatpak fontconfig unzip
      ;;
    arch)
      sudo pacman -Sy --needed --noconfirm \
        base-devel curl wget git file procps-ng ca-certificates gnupg \
        zsh flatpak fontconfig unzip
      ;;
  esac
}

install_chrome() {
  command_exists google-chrome && return 0
  case "$distro" in
    debian)
      wget -qO /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
      sudo apt-get install -y /tmp/chrome.deb
      ;;
    fedora)
      wget -qO /tmp/chrome.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
      sudo dnf install -y /tmp/chrome.rpm
      ;;
    # Chrome is AUR-only on Arch; Chromium from Flathub keeps the PWA shortcuts working.
    arch) flatpak install -y --noninteractive flathub org.chromium.Chromium ;;
  esac
}

install_vscode() {
  command_exists code && return 0
  case "$distro" in
    debian)
      wget -qO /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
      sudo apt-get install -y /tmp/vscode.deb
      ;;
    fedora)
      wget -qO /tmp/vscode.rpm "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
      sudo dnf install -y /tmp/vscode.rpm
      ;;
    arch) flatpak install -y --noninteractive flathub com.visualstudio.code ;;
  esac
}

install_docker() {
  command_exists docker && return 0
  if [ "$distro" = "arch" ]; then
    sudo pacman -S --needed --noconfirm docker docker-compose
  else
    # Official script, and it already knows Debian, Ubuntu, Mint and Fedora.
    curl -fsSL https://get.docker.com | sudo sh
  fi
  sudo systemctl enable --now docker || true
  sudo usermod -aG docker "$USER" || true
  warn "Docker: log out and back in to use it without sudo"
}

log "System base"
install_base
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

if ! command_exists brew; then
  log "Installing Homebrew on Linux"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew update

log "brew: formulae from the Brewfile"
grep -E '^brew ' "$SCRIPT_DIR/../macos/Brewfile" \
  | sed -E 's/^brew "([^"]+)".*/\1/' \
  | grep -vE '^(cocoapods|mas)$' \
  | while read -r f; do brew list "$f" >/dev/null 2>&1 || brew install "$f" || warn "brew failed: $f"; done

log "GUI apps"
install_chrome || warn "Chrome failed"
install_vscode || warn "VS Code failed"
install_docker || warn "Docker failed"

log "Flatpak apps"
for app in \
  dev.zed.Zed \
  io.dbeaver.DBeaverCommunity \
  com.usebruno.Bruno \
  md.obsidian.Obsidian \
  com.discordapp.Discord \
  com.mongodb.Compass \
  org.libreoffice.LibreOffice ; do
  flatpak install -y --noninteractive flathub "$app" || warn "flatpak failed: $app"
done

log "PWA shortcuts"
mkdir -p "$HOME/.local/share/applications"
make_pwa() {
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

log "Linux packages done"
