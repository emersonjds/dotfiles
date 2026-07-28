#!/usr/bin/env bash
# Terminal settings that live in .plist files and cannot be versioned as text.
# Run with iTerm2 CLOSED, otherwise it overwrites these defaults on exit.
set -euo pipefail

FONT="JetBrainsMono Nerd Font Mono 14"
PS_FONT="JetBrainsMonoNFM-Regular"   # PostScript name, required by Terminal.app
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
PROFILE_GUID="emerson-tokyonight-2026"

defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$PROFILE_GUID"

# Pin the Nerd Font on iTerm2's built-in "Default" profile (index 0) as well.
pb() { /usr/libexec/PlistBuddy -c "$1" "$ITERM_PLIST"; }
pb "Set 'New Bookmarks':0:'Normal Font' '$FONT'"
pb "Set 'New Bookmarks':0:'Non Ascii Font' '$FONT'"
pb "Set 'New Bookmarks':0:'Use Non-ASCII Font' false" 2>/dev/null \
  || pb "Add 'New Bookmarks':0:'Use Non-ASCII Font' bool false"

osascript <<OSA
tell application "Terminal"
    set font name of settings set "Basic" to "$PS_FONT"
    set font size of settings set "Basic" to 14
end tell
OSA

echo "done — open a new window to see it."
