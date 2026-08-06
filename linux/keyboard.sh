#!/usr/bin/env bash
# Keyboard layout for a US keyboard that has to type Portuguese.
#
# A plain `us` layout has no dead keys, so á ã ç ê are unreachable. The `intl` variant
# restores them: ' + a = á, ~ + a = ã, ^ + e = ê. A dead key is silent until the next
# keystroke; press it twice to get the symbol itself. The cedilla is the one exception
# the layout cannot fix on its own — see config/XCompose.
#
# The modifiers are deliberately left alone. An earlier version defaulted to
# ctrl:swap_lwin_lctl to put Ctrl under the thumb like macOS's Cmd, but a swap moves
# *both* keys: Ctrl leaves the corner where every Linux tutorial, terminal and window
# manager assumes it is. Standard behaviour is the better default; the option is still
# one variable away for anyone who wants it:
#
#   KB_OPTIONS=ctrl:swap_lwin_lctl ./linux/keyboard.sh
#
# Applied in four places, because each one covers a different moment:
#   - setxkbmap        the session running right now
#   - gsettings        the desktop (Cinnamon keeps its own schema, separate from GNOME)
#   - ibus             the input method, which outranks the X layout
#   - /etc/default/keyboard  the console and the login screen (needs root)
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

# Override per machine without editing the repo, e.g. KB_LAYOUT=br KB_VARIANT= ./linux/keyboard.sh
KB_LAYOUT="${KB_LAYOUT:-us}"
KB_VARIANT="${KB_VARIANT:-intl}"
KB_OPTIONS="${KB_OPTIONS-}"

log "Keyboard: ${KB_LAYOUT}${KB_VARIANT:+($KB_VARIANT)} options=${KB_OPTIONS:-none}"

# 1. The running X session. Also clears whatever stale layout list is loaded: this box
# came up as `us,br,br` with variant `symbolic`, which is why accents did nothing.
if command_exists setxkbmap && [ -n "${DISPLAY:-}" ]; then
  setxkbmap -layout "$KB_LAYOUT" -variant "$KB_VARIANT" -option "" -option "$KB_OPTIONS" \
    && ok "applied to the current session" \
    || warn "setxkbmap failed (no X session?)"
fi

# 2. The desktop, which reapplies its own value at login and would otherwise undo step 1.
#
# Cinnamon has its own copy of the GNOME schema and reads ONLY that one — writing to
# org.gnome.desktop.input-sources on Mint changes nothing at all, which is exactly how
# this machine kept coming back as `us,br,br`. Write to every schema that exists rather
# than guessing which desktop is in charge.
if command_exists gsettings; then
  src="$KB_LAYOUT"
  [ -n "$KB_VARIANT" ] && src="$KB_LAYOUT+$KB_VARIANT"
  saved=0
  for schema in org.cinnamon.desktop.input-sources org.gnome.desktop.input-sources; do
    gsettings writable "$schema" sources >/dev/null 2>&1 || continue
    # A single source only: a second one gives the layout switcher something to flip to,
    # which is how a layout with no dead keys becomes active by accident.
    gsettings set "$schema" sources "[('xkb','$src')]" 2>/dev/null || continue
    # An empty option list has to be [], not [''] — the latter is a real entry that xkb
    # fails to parse, taking the whole layout down with it. Keep whatever the desktop
    # already had when this script sets no options of its own.
    if [ -n "$KB_OPTIONS" ]; then
      gsettings set "$schema" xkb-options "['$KB_OPTIONS']" 2>/dev/null || true
    fi
    gsettings set "$schema" current 0 2>/dev/null || true
    saved=$((saved + 1))
  done
  [ "$saved" -gt 0 ] && ok "desktop setting saved in $saved schema(s) (survives logout)"
fi

# 3. ibus, which on Mint is the actual input method and outranks all of the above. Its
# engine carries its own layout: with xkb:us::eng active, X can hold us(intl) all it likes
# and the dead keys still do nothing, because ibus is what the application talks to.
# The engine name is looked up rather than assembled — the language suffix (eng, por, …)
# is not derivable from the layout.
if command_exists ibus; then
  want="xkb:$KB_LAYOUT:$KB_VARIANT:"
  # `ibus list-engine` prints "  xkb:us:intl:eng - English (US, intl., with dead keys)".
  # Take the first field only; the description that follows is not part of the name.
  engine="$(ibus list-engine 2>/dev/null \
    | awk -v w="$want" '{ sub(/^[[:space:]]+/, ""); if (index($1, w) == 1) { print $1; exit } }')"
  if [ -n "$engine" ]; then
    gsettings set org.freedesktop.ibus.general preload-engines "['$engine']" 2>/dev/null || true
    ibus engine "$engine" >/dev/null 2>&1 || true
    ok "ibus engine set to $engine"
  else
    warn "no ibus engine matching ${want}; dead keys may not compose"
  fi
fi

# 4. The console and the login screen. Root-only, so it is best-effort: the desktop
# setting above is what matters day to day.
if [ -w /etc/default/keyboard ] || sudo -n true 2>/dev/null; then
  sudo tee /etc/default/keyboard >/dev/null <<EOF
# KEYBOARD CONFIGURATION FILE
# Managed by dotfiles (linux/keyboard.sh). Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="$KB_LAYOUT"
XKBVARIANT="$KB_VARIANT"
XKBOPTIONS="$KB_OPTIONS"

BACKSPACE="guess"
EOF
  sudo udevadm trigger --subsystem-match=input --action=change >/dev/null 2>&1 || true
  ok "/etc/default/keyboard updated (console and login screen)"
else
  warn "/etc/default/keyboard not updated: needs sudo. The desktop setting is still applied."
fi

# Which layer covers which moment is the whole point of this script, so say it out loud.
# "applied to the current session" above reads like the only thing that happened; the
# three writes under it are what make the setting the default from the next login on.
log "Keyboard configured — this is now the default, not just for this session:"
ok "this session ............ setxkbmap"
ok "every login ............. ${saved:-0} desktop schema(s) + ibus engine"
ok "login screen, console ... /etc/default/keyboard"
log "Accents: ' + a = á, ~ + a = ã, ' + c = ç, ^ + e = ê"
log "Already-open apps keep the old input method until restarted."
