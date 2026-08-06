#!/usr/bin/env bash
# Debian/Ubuntu/Mint, Fedora and Arch. Only the system base and the GUI apps are
# distro-specific: every CLI comes from Homebrew on Linux, which is distro-agnostic.
#
# The Brewfile is a macOS snapshot, so this stage also stands in for the parts of it
# that Linux cannot take from brew: the casks. Flutter, the Android SDK, ngrok, uv and
# the Nerd Font are installed from their upstream tarballs here, which keeps them
# distro-agnostic too.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

distro="$(detect_os)"
log "System: $(os_description)"
log "Package family: $distro (apt/dnf/pacman path; every derivative shares one)"

# Formulae that exist only for macOS. kdoctor diagnoses an Xcode toolchain and ships no
# Linux bottle; cocoapods and clipaste are equally macOS-shaped; mas is the App Store.
MAC_ONLY_FORMULAE='cocoapods|mas|kdoctor|clipaste'

# One failure in a batch aborts the whole batch, and these are the nice-to-haves whose
# names drift between releases (libfuse2 -> libfuse2t64 on noble). Install them one by one.
apt_optional() {
  local p
  for p in "$@"; do
    sudo apt-get install -y "$p" >/dev/null 2>&1 || warn "apt: skipped unavailable package $p"
  done
}

install_base() {
  case "$distro" in
    debian)
      sudo apt-get update -y
      sudo apt-get install -y \
        build-essential curl wget git file procps ca-certificates gnupg \
        zsh flatpak fontconfig unzip zip xz-utils apt-transport-https lsb-release \
        python3-pip python3-venv
      # Flutter's Linux desktop toolchain, the emulator's GL stack, and the keyring
      # VS Code and Chrome expect. Optional: a missing one must not stop the install.
      apt_optional clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
        libglu1-mesa libsecret-1-0 libfuse2t64 libfuse2
      ;;
    fedora)
      sudo dnf install -y --skip-unavailable \
        @development-tools curl wget git file procps-ng ca-certificates gnupg2 \
        zsh flatpak fontconfig unzip zip xz \
        clang cmake ninja-build pkgconf-pkg-config gtk3-devel xz-devel \
        mesa-libGLU libsecret python3-pip
      ;;
    arch)
      sudo pacman -Sy --needed --noconfirm \
        base-devel curl wget git file procps-ng ca-certificates gnupg \
        zsh flatpak fontconfig unzip zip xz \
        clang cmake ninja pkgconf gtk3 xz glu libsecret python-pip
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
    arch) flatpak install --user -y --noninteractive flathub org.chromium.Chromium ;;
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
    arch) flatpak install --user -y --noninteractive flathub com.visualstudio.code ;;
  esac
}

# get.docker.com is not safe on the Ubuntu derivatives. It only finds the upstream
# release through `lsb_release -u`, which Mint's lsb_release does not implement; it then
# falls back to /etc/debian_version, reads "trixie/sid", and wires up a Debian repo on a
# machine that is really Ubuntu noble. Point apt at the right repo ourselves instead.
install_docker() {
  command_exists docker && return 0
  case "$distro" in
    arch)
      sudo pacman -S --needed --noconfirm docker docker-compose
      ;;
    debian)
      local codename
      codename="$(ubuntu_codename)" || { warn "no Ubuntu codename; skipped Docker"; return 0; }
      log "Docker: apt repo for ubuntu/$codename"
      sudo install -m 0755 -d /etc/apt/keyrings
      sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      sudo apt-get update -y
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
      ;;
    fedora)
      curl -fsSL https://get.docker.com | sudo sh
      ;;
  esac
  sudo systemctl enable --now docker || true
  sudo usermod -aG docker "$USER" || true
  warn "Docker: log out and back in to use it without sudo"
}

# cask "ghostty" on macOS. Ghostty publishes no Linux binary and is not on Flathub, so
# Debian takes the community builds from mkasberg/ghostty-ubuntu — the .deb everyone in
# the Ubuntu world actually uses, but third-party all the same. Arch has it in extra.
install_ghostty() {
  command_exists ghostty && return 0
  case "$distro" in
    arch)
      sudo pacman -S --needed --noconfirm ghostty || { warn "ghostty failed"; return 0; }
      ;;
    debian)
      # The asset is named for the Ubuntu release, which on Mint is not VERSION_ID.
      # distro-info maps the codename to it without a table to keep up to date.
      local codename ver url
      codename="$(ubuntu_codename)" || { warn "no Ubuntu codename; skipped Ghostty"; return 0; }
      ver="$(awk -F, -v c="$codename" '$3 == c {print $1}' /usr/share/distro-info/ubuntu.csv 2>/dev/null \
             | sed 's/ LTS//' | head -1)"
      [ -n "$ver" ] || { warn "could not map $codename to an Ubuntu version; skipped Ghostty"; return 0; }
      url="$(curl -fsSL https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest 2>/dev/null \
        | python3 -c "
import json, sys
want = '_$(dpkg --print-architecture)_${ver}.deb'
d = json.load(sys.stdin)
for a in d.get('assets', []):
    if a['name'].endswith(want):
        print(a['browser_download_url']); break
" 2>/dev/null)" || true
      [ -n "$url" ] || { warn "no Ghostty build for $ver; skipped"; return 0; }
      log "Ghostty: $ver build"
      wget -qO /tmp/ghostty.deb "$url" || { warn "Ghostty download failed"; return 0; }
      sudo apt-get install -y /tmp/ghostty.deb || warn "Ghostty install failed"
      rm -f /tmp/ghostty.deb
      ;;
    fedora)
      sudo dnf copr enable -y scottames/ghostty >/dev/null 2>&1 \
        && sudo dnf install -y ghostty || warn "Ghostty failed"
      ;;
  esac
}

# Installing a terminal is not choosing one: the desktop keeps its own answer in three
# places, and whichever one the caller happens to use is the one that decides.
set_default_terminal() {
  command_exists ghostty || return 0
  local schema="org.cinnamon.desktop.default-applications.terminal"

  # What Ctrl+Alt+T and "Open in terminal" ask for on Cinnamon. Read the value back: a
  # gsettings write can be accepted and then dropped when the session's own daemon holds
  # a competing copy, and `|| true` on the write alone reports success either way.
  if command_exists gsettings && gsettings writable "$schema" exec >/dev/null 2>&1; then
    gsettings set "$schema" exec ghostty 2>/dev/null || true
    gsettings set "$schema" exec-arg '-e' 2>/dev/null || true
    case "$(gsettings get "$schema" exec 2>/dev/null)" in
      *ghostty*) ok "Cinnamon: Ctrl+Alt+T opens Ghostty" ;;
      *) warn "Cinnamon kept $(gsettings get "$schema" exec) as the terminal; set it in Preferred Applications" ;;
    esac
  fi

  # What Debian's x-terminal-emulator resolves to, for anything going through alternatives.
  if command_exists update-alternatives && [ -x /usr/bin/ghostty ]; then
    sudo update-alternatives --install /usr/bin/x-terminal-emulator \
      x-terminal-emulator /usr/bin/ghostty 60 >/dev/null 2>&1 || true
    sudo update-alternatives --set x-terminal-emulator /usr/bin/ghostty >/dev/null 2>&1 \
      && ok "x-terminal-emulator -> ghostty" \
      || warn "could not set the x-terminal-emulator alternative"
  fi

  # What the XDG spec tells desktop-agnostic apps to read.
  mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
  echo "com.mitchellh.ghostty.desktop" > "${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list"
  ok "xdg-terminals.list -> com.mitchellh.ghostty.desktop"
}

# cask "ngrok" on macOS. The upstream tarball needs no repo or signing key.
install_ngrok() {
  command_exists ngrok && return 0
  log "ngrok"
  mkdir -p "$HOME/.local/bin"
  wget -qO /tmp/ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
  tar -xzf /tmp/ngrok.tgz -C "$HOME/.local/bin" ngrok
  chmod +x "$HOME/.local/bin/ngrok"
  rm -f /tmp/ngrok.tgz
}

# doctor.sh checks for uv, and nothing else installs it: pipx would work but the
# official installer drops it straight into ~/.local/bin, which is already on PATH.
install_uv() {
  command_exists uv && { uv self update >/dev/null 2>&1 || true; return 0; }
  log "uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || warn "uv install failed"
}

# cask "android-commandlinetools" + cask "android-platform-tools" on macOS.
# sdkmanager is a Java program, so this has to run after the brew stage installed openjdk.
install_android_sdk() {
  local sdk="$HOME/Android/Sdk"
  local tools="$sdk/cmdline-tools/latest"
  export ANDROID_HOME="$sdk" ANDROID_SDK_ROOT="$sdk"

  if [ ! -x "$tools/bin/sdkmanager" ]; then
    log "Android SDK: command-line tools"
    mkdir -p "$sdk/cmdline-tools"
    wget -qO /tmp/cmdline-tools.zip \
      https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
      || { warn "could not download the Android command-line tools"; return 0; }
    rm -rf /tmp/cmdline-tools-extract
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extract
    rm -rf "$tools"
    # The zip unpacks as cmdline-tools/; sdkmanager insists on living in .../latest.
    mv /tmp/cmdline-tools-extract/cmdline-tools "$tools"
    rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools-extract
  fi

  # sdkmanager rejects anything newer than JDK 17, so pin it to the one the Brewfile installs.
  local jdk=""
  for c in "$(brew --prefix openjdk@17 2>/dev/null)" /usr/lib/jvm/java-17-openjdk-amd64; do
    [ -n "$c" ] && [ -x "$c/bin/java" ] && { jdk="$c"; break; }
  done
  [ -n "$jdk" ] || { warn "no JDK 17; skipped the Android SDK packages"; return 0; }

  log "Android SDK: platform-tools, build-tools, platform"
  JAVA_HOME="$jdk" yes 2>/dev/null | "$tools/bin/sdkmanager" --licenses >/dev/null 2>&1 || true
  JAVA_HOME="$jdk" "$tools/bin/sdkmanager" \
    "platform-tools" "build-tools;34.0.0" "platforms;android-34" >/dev/null 2>&1 \
    || warn "sdkmanager could not install the SDK packages"
}

# cask "flutter" on macOS. The release channel JSON avoids hardcoding a version.
install_flutter() {
  local dir="$HOME/development/flutter"
  if [ -x "$dir/bin/flutter" ]; then
    log "Flutter: upgrading"
    git -C "$dir" pull --ff-only >/dev/null 2>&1 || warn "flutter upgrade failed"
    return 0
  fi
  log "Flutter: stable channel"
  local url
  url="$(curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json 2>/dev/null \
    | python3 -c '
import json, sys
d = json.load(sys.stdin)
stable = d["current_release"]["stable"]
for r in d["releases"]:
    if r["hash"] == stable:
        print(d["base_url"] + "/" + r["archive"]); break
' 2>/dev/null)" || true
  [ -n "$url" ] || { warn "could not resolve the Flutter release; skipped"; return 0; }
  mkdir -p "$HOME/development"
  wget -qO /tmp/flutter.tar.xz "$url" || { warn "Flutter download failed"; return 0; }
  tar -xf /tmp/flutter.tar.xz -C "$HOME/development"
  rm -f /tmp/flutter.tar.xz
  # Flutter refuses to run from a directory another user could have tampered with.
  git config --global --add safe.directory "$dir" 2>/dev/null || true
}

# The casks font-jetbrains-mono-nerd-font and friends. starship's prompt and `eza --icons`
# both render as tofu without a patched font.
install_nerd_font() {
  local dir="$HOME/.local/share/fonts"
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    return 0
  fi
  log "JetBrains Mono Nerd Font"
  mkdir -p "$dir"
  wget -qO /tmp/jbmono.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
    || { warn "Nerd Font download failed"; return 0; }
  unzip -qo /tmp/jbmono.zip -d "$dir/JetBrainsMono" -x 'README.md' 'LICENSE.txt' 'OFL.txt'
  rm -f /tmp/jbmono.zip
  fc-cache -f "$dir" >/dev/null 2>&1 || true
}

# An installed font is not a used font: GNOME Terminal keeps its own per-profile setting,
# and Mint ships it as the default terminal.
set_terminal_font() {
  command_exists gsettings || return 0
  local profile
  profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")" || return 0
  [ -n "$profile" ] || return 0
  local path="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
  gsettings set "$path" use-system-font false 2>/dev/null || return 0
  gsettings set "$path" font 'JetBrainsMono Nerd Font 11' 2>/dev/null || return 0
  log "GNOME Terminal: font set to JetBrainsMono Nerd Font"
}

# Sourcing this file defines the install_* functions and stops there; executing it runs
# the full stage. Lets a partial or interrupted run be resumed a step at a time.
[ "${BASH_SOURCE[0]}" = "${0}" ] || return 0

log "System base"
install_base
# --user throughout: a system-wide install goes through polkit, which means an
# authentication dialog and a hang when this script is not run from a desktop session.
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

if load_brew; then
  log "Homebrew: already installed ($(brew --prefix))"
else
  log "Installing Homebrew on Linux"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew || { err "Homebrew install failed"; exit 1; }
fi
brew update

# `brew "supabase"` only resolves once supabase/tap is tapped, and since Homebrew 6.0 a
# third-party tap also has to be trusted before its formulae will load. `brew bundle`
# reads the `trusted: true` marker on macOS; here the Brewfile is parsed by hand, so both
# steps are done explicitly.
log "brew: taps from the Brewfile"
grep -E '^tap ' "$SCRIPT_DIR/../macos/Brewfile" \
  | sed -E 's/^tap "([^"]+)".*/\1/' \
  | grep -vE "^hqhq1025/" \
  | while read -r t; do
      brew tap "$t" >/dev/null 2>&1 </dev/null || warn "brew tap failed: $t"
      brew trust --tap "$t" >/dev/null 2>&1 </dev/null || true
    done

# </dev/null on every brew call: brew reads stdin, and inside a `while read` loop it
# swallows the rest of the formula list, so only the first one ever gets installed.
log "brew: formulae from the Brewfile"
grep -E '^brew ' "$SCRIPT_DIR/../macos/Brewfile" \
  | sed -E 's/^brew "([^"]+)".*/\1/' \
  | grep -vE "(^|/)($MAC_ONLY_FORMULAE)\$" \
  | while read -r f; do
      if brew list "$f" >/dev/null 2>&1 </dev/null; then
        brew upgrade "$f" >/dev/null 2>&1 </dev/null || true
      else
        brew install "$f" </dev/null || warn "brew failed: $f"
      fi
    done

log "GUI apps"
install_chrome  || warn "Chrome failed"
install_vscode  || warn "VS Code failed"
install_docker  || warn "Docker failed"
install_ghostty || warn "Ghostty failed"

log "Toolchains the Brewfile ships as macOS casks"
install_ngrok       || warn "ngrok failed"
install_uv          || warn "uv failed"
install_flutter     || warn "Flutter failed"
install_android_sdk || warn "Android SDK failed"

log "Fonts"
install_nerd_font || warn "Nerd Font failed"
set_terminal_font || true

log "Default terminal"
set_default_terminal || warn "could not set the default terminal"

log "Keyboard"
bash "$SCRIPT_DIR/keyboard.sh" || warn "keyboard setup failed"

log "System language"
bash "$SCRIPT_DIR/locale.sh" || warn "locale setup failed"
# A .deb built by the people who make the app is the closest Linux gets to a macOS cask.
# Flathub is the fallback, not the first choice: every entry for these apps is a community
# repackage — not one of them is vendor-verified — so prefer upstream where it exists.
install_vendor_deb() {  # <command> <name> <url>
  local cmd="$1" name="$2" url="$3"
  command_exists "$cmd" && return 0
  [ -n "$url" ] || { warn "$name: could not resolve a download URL; skipped"; return 0; }
  log "$name (official .deb)"
  wget -qO /tmp/vendor.deb "$url" || { warn "$name: download failed"; return 0; }
  # A vendor URL that answers 200 with an HTML error page would otherwise reach apt.
  case "$(file -b --mime-type /tmp/vendor.deb 2>/dev/null)" in
    application/vnd.debian.binary-package|application/x-debian-package) ;;
    *) warn "$name: download was not a .deb; skipped"; rm -f /tmp/vendor.deb; return 0 ;;
  esac
  sudo apt-get install -y /tmp/vendor.deb || warn "$name: install failed"
  rm -f /tmp/vendor.deb
}

# Newest release asset ending in <suffix>, for the vendors who publish on GitHub.
# Trailing arguments are substrings to reject, which is how the plain build wins over the
# "isolated" and "readonly" variants shipped beside it.
github_deb_url() {  # <owner/repo> <suffix> [reject]...
  local repo="$1"; shift
  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
    | python3 -c "
import json, sys
suffix, reject = sys.argv[1], sys.argv[2:]
for a in json.load(sys.stdin).get('assets', []):
    n = a['name']
    if n.endswith(suffix) and not any(r in n for r in reject):
        print(a['browser_download_url']); break
" "$@" 2>/dev/null
}

# Zed ships an install script instead of a package; it is the documented Linux path.
install_zed() {
  command_exists zed && return 0
  log "Zed (official installer)"
  curl -fsSL https://zed.dev/install.sh | sh >/dev/null 2>&1 || warn "Zed install failed"
}

# Telegram publishes a tarball, no repo. It registers its own .desktop on first launch.
install_telegram() {
  command_exists telegram-desktop && return 0
  [ -x "$HOME/.local/opt/Telegram/Telegram" ] && return 0
  log "Telegram (official tarball)"
  wget -qO /tmp/telegram.tar.xz https://telegram.org/dl/desktop/linux \
    || { warn "Telegram download failed"; return 0; }
  mkdir -p "$HOME/.local/opt"
  tar -xf /tmp/telegram.tar.xz -C "$HOME/.local/opt" || { warn "Telegram extract failed"; return 0; }
  rm -f /tmp/telegram.tar.xz
  ln -sf "$HOME/.local/opt/Telegram/Telegram" "$HOME/.local/bin/telegram-desktop"
}

# Deliberately not installed. A browser shortcut dressed up as a launcher is not a port:
# it still has no notifications, no file handlers and no offline mode, while looking in
# the menu exactly like something that does. Point at the native tool instead.
no_linux_app_notice() {
  cat <<'EOF'

  No official Linux build. Use the native tool rather than a fake "app":

    Outlook   ->  Thunderbird, which Mint already installs
    Notion    ->  Obsidian, installed above; or notion.so in a browser tab
    Linear    ->  linear.app in a browser tab; there is no Linux desktop client
    WhatsApp  ->  web.whatsapp.com; every Flathub client is unofficial

EOF
}

if [ "$distro" = "debian" ]; then
  log "Apps with an official Linux build"
  install_vendor_deb discord         "Discord"         "https://discord.com/api/download?platform=linux&format=deb"
  install_vendor_deb dbeaver         "DBeaver"         "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb"
  install_vendor_deb obsidian        "Obsidian"        "$(github_deb_url obsidianmd/obsidian-releases _amd64.deb)"
  install_vendor_deb bruno           "Bruno"           "$(github_deb_url usebruno/bruno _amd64_linux.deb)"
  install_vendor_deb mongodb-compass "MongoDB Compass" "$(github_deb_url mongodb-js/compass _amd64.deb isolated readonly)"
  install_zed      || warn "Zed failed"
  install_telegram || warn "Telegram failed"
  # Shipped and maintained by the distro, which is upstream enough.
  apt_optional libreoffice thunderbird
else
  # No vendor .deb story on Fedora/Arch, so Flathub is the pragmatic choice there.
  log "Flatpak apps"
  for app in \
    dev.zed.Zed \
    io.dbeaver.DBeaverCommunity \
    com.usebruno.Bruno \
    md.obsidian.Obsidian \
    com.discordapp.Discord \
    org.telegram.desktop \
    com.mongodb.Compass \
    org.libreoffice.LibreOffice ; do
    flatpak install --user -y --noninteractive flathub "$app" || warn "flatpak failed: $app"
  done
  flatpak update --user -y --noninteractive || true
fi

# Earlier versions of this script created browser shortcuts for WhatsApp, Outlook, Notion
# and Linear. They are gone; clear out what a previous run left in the menu.
for stale in whatsapp-pwa outlook-pwa notion-pwa linear-pwa; do
  rm -f "$HOME/.local/share/applications/$stale.desktop" "$HOME/.local/share/icons/$stale".*
done
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

no_linux_app_notice

log "Linux packages done"
