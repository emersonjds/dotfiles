#!/usr/bin/env bash
# System language. shell/env.sh already forces LC_ALL=en_US.UTF-8 for the terminal, so
# this aligns the desktop with it instead of leaving the two disagreeing.
#
# Deliberately does NOT rename the XDG user directories. Switching language normally
# offers to turn ~/Documentos into ~/Documents, which silently moves every path anyone
# has ever hardcoded — this repo included, since it lives under ~/Documentos. The folder
# names stay; only the interface language changes.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/../lib/common.sh"

LOCALE_LANG="${LOCALE_LANG:-en_US.UTF-8}"
LOCALE_LANGUAGE="${LOCALE_LANGUAGE:-en_US:en}"

current="$(. /etc/default/locale 2>/dev/null && echo "${LANG:-}")"
if [ "$current" = "$LOCALE_LANG" ]; then
  ok "system language is already $LOCALE_LANG"
  exit 0
fi

log "System language: $current -> $LOCALE_LANG"

if ! sudo -n true 2>/dev/null && [ ! -w /etc/default/locale ]; then
  warn "system language not changed: needs sudo. Run ./linux/locale.sh directly."
  exit 0
fi

# update-locale writes a locale that was never generated without complaining, and the
# session then falls back to C. Generate it first.
if ! locale -a 2>/dev/null | grep -qix "${LOCALE_LANG/UTF-8/utf8}"; then
  log "generating $LOCALE_LANG"
  sudo locale-gen "$LOCALE_LANG" >/dev/null 2>&1 || warn "locale-gen failed"
fi

sudo update-locale LANG="$LOCALE_LANG" LANGUAGE="$LOCALE_LANGUAGE" LC_ALL= \
  || { warn "update-locale failed"; exit 0; }

# Cinnamon reads its own copy for the greeter and the session menus.
if command_exists gsettings; then
  gsettings set org.gnome.system.locale region "$LOCALE_LANG" 2>/dev/null || true
fi

ok "system language set to $LOCALE_LANG (takes effect after logout)"
log "User folders keep their current names on purpose (~/Documentos stays put)."
