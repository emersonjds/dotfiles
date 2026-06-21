#!/usr/bin/env bash
# Ajustes de terminal que vivem em .plist (não dá pra versionar como arquivo de texto).
# Rode com o iTerm2 FECHADO para os defaults não serem sobrescritos ao sair.
set -euo pipefail

FONT="JetBrainsMono Nerd Font Mono 14"
PS_FONT="JetBrainsMonoNFM-Regular"   # nome PostScript (Terminal.app)
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
EMERSON_GUID="emerson-tokyonight-2026"

# --- iTerm2: profile Emerson como padrão ---
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$EMERSON_GUID"

# --- iTerm2: blinda o profile "Default" (índice 0) com a Nerd Font ---
pb() { /usr/libexec/PlistBuddy -c "$1" "$ITERM_PLIST"; }
pb "Set 'New Bookmarks':0:'Normal Font' '$FONT'"
pb "Set 'New Bookmarks':0:'Non Ascii Font' '$FONT'"
pb "Set 'New Bookmarks':0:'Use Non-ASCII Font' false" 2>/dev/null \
  || pb "Add 'New Bookmarks':0:'Use Non-ASCII Font' bool false"

# --- Terminal.app: fonte do profile Basic (via AppleScript) ---
osascript <<OSA
tell application "Terminal"
    set font name of settings set "Basic" to "$PS_FONT"
    set font size of settings set "Basic" to 14
end tell
OSA

echo "ok — terminais ajustados (abra janelas novas para ver)."
