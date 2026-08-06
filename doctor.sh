#!/usr/bin/env bash
# Checks the machine against the repo: configs, shell environment, packages.
# Reads only. Exits non-zero when something needs attention.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

problems=0
note() { warn "$*"; problems=$((problems + 1)); }

TOOLS="zsh git brew starship zoxide fzf eza rg nvim
node npm npx pnpm yarn bun claude
java javac mvn
python3 pipx uv
ruby gem rbenv cargo rustc
flutter dart adb adbe watchman ngrok
psql mysql supabase gh docker shellcheck"
# Tools only one OS can have: cocoapods, mas and kdoctor (an Xcode toolchain probe)
# are macOS-only, and flatpak carries the GUI apps that arrive as casks there.
if [ "$(uname -s)" = "Darwin" ]; then
  TOOLS="$TOOLS pod mas kdoctor"
else
  TOOLS="$TOOLS flatpak"
fi
VERSIONED="zsh git brew node npm java python3 ruby cargo"
VARS="JAVA_HOME ANDROID_HOME ANDROID_SDK_ROOT NVM_DIR BUN_INSTALL PNPM_HOME"

# A nested shell inherits an already-built PATH, which hides ordering bugs and
# missing exports. Starting from a bare environment reproduces a real new terminal.
#
# Every "is this installed" question has to be asked through here, not in doctor's own
# shell: brew's npm and nvm's npm keep separate global roots, so asking the wrong one
# reports every global package missing while the terminal has them all.
login_shell_run() {
  env -i HOME="$HOME" USER="${USER:-}" TERM="${TERM:-xterm}" SHELL=/bin/zsh \
    PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    zsh -lic "$1" 2>/dev/null
}

probe_login_shell() {
  local tools; tools="$(echo "$TOOLS" | tr '\n' ' ')"
  login_shell_run '
      for c in '"$tools"'; do print -r -- "cmd|$c|$(command -v $c 2>/dev/null)"; done
      for c in '"$VERSIONED"'; do print -r -- "ver|$c|$($c --version 2>/dev/null | head -1)"; done
      for v in '"$VARS"'; do print -r -- "var|$v|${(P)v}"; done
      print -r -- "path|PATH|$PATH"
    '
}

field() { printf '%s\n' "$SHELL_DUMP" | grep "^$1|$2|" | cut -d'|' -f3-; }

log "Configs (repo -> machine)"
while IFS='|' read -r rel dest; do
  [ -n "$rel" ] || continue
  if [ ! -r "$dest" ]; then
    note "missing: $dest  (run ./install.sh --configs-only)"
  elif ! cmp -s "$dest" "$DOTFILES_DIR/$rel"; then
    note "drifted: $rel  (./install.sh --configs-only to push, ./sync.sh to pull)"
  fi
done < <(dotfiles_map)
[ "$problems" -eq 0 ] && ok "all files match the repo"

log "Login shell"
SHELL_DUMP="$(probe_login_shell)"
[ -n "$SHELL_DUMP" ] || { err "could not start a login zsh"; exit 1; }

missing=""
for c in $TOOLS; do
  [ -n "$(field cmd "$c")" ] || missing="$missing $c"
done
if [ -n "$missing" ]; then
  note "not on PATH in a new terminal:$missing"
else
  ok "all $(echo "$TOOLS" | wc -w | tr -d ' ') tools resolve on PATH"
fi

for c in $VERSIONED; do
  v="$(field ver "$c")"
  [ -n "$v" ] && ok "$c: $v"
done

# PATH order decides which copy of a tool wins, so check the ones with two copies.
java_bin="$(field cmd java)"
java_home="$(field var JAVA_HOME)"
case "$java_bin" in
  "$java_home"/*) ok "java comes from JAVA_HOME" ;;
  "") : ;;
  *) note "java resolves to $java_bin, not JAVA_HOME ($java_home)" ;;
esac

if command_exists rbenv && [ -n "$(rbenv versions --bare 2>/dev/null)" ]; then
  case "$(field cmd ruby)" in
    */shims/*) ok "ruby comes from rbenv" ;;
    *) note "ruby resolves to $(field cmd ruby), not the rbenv shims" ;;
  esac
elif command_exists rbenv; then
  note "rbenv has no Ruby installed, so ruby falls back to the system copy (run ./install.sh)"
fi

dups="$(printf '%s\n' "$(field path PATH)" | tr ':' '\n' | sort | uniq -d | tr '\n' ' ')"
[ -n "$dups" ] && note "duplicate PATH entries: $dups"

log "Environment"
for v in $VARS; do
  val="$(field var "$v")"
  if [ -z "$val" ]; then
    note "$v: unset in a new terminal"
  elif [ ! -d "$val" ]; then
    note "$v: points to a missing directory ($val)"
  else
    ok "$v=$val"
  fi
done

if command_exists brew && [ "$(uname -s)" = "Darwin" ]; then
  log "Homebrew packages"
  if brew bundle check --file="$SCRIPT_DIR/macos/Brewfile" >/dev/null 2>&1; then
    ok "Brewfile satisfied"
  else
    brew bundle check --file="$SCRIPT_DIR/macos/Brewfile" --verbose 2>&1 \
      | grep '^→' | sed 's/^→/ /'
    note "Brewfile not satisfied (run ./install.sh to install and upgrade)"
  fi
fi

log "npm globals"
installed="$(login_shell_run 'npm ls -g --depth=0 --parseable')"
while read -r pkg; do
  case "$installed" in
    *"/node_modules/$pkg"*) ok "$pkg" ;;
    *) note "npm global missing: $pkg" ;;
  esac
done < <(grep -vE '^[[:space:]]*(#|$)' "$SCRIPT_DIR/packages/npm-global.txt")

if cli="$(vscode_cli)"; then
  log "VS Code extensions"
  exts="$("$cli" --list-extensions 2>/dev/null | tr 'A-Z' 'a-z')"
  while read -r ext; do
    case "$exts" in
      *"$(echo "$ext" | tr 'A-Z' 'a-z')"*) : ;;
      *) note "extension missing: $ext" ;;
    esac
  done < <(grep -vE '^[[:space:]]*(#|$)' "$SCRIPT_DIR/packages/vscode-extensions.txt")
  ok "$(printf '%s\n' "$exts" | grep -c .) extensions installed"
fi

echo
if [ "$problems" -eq 0 ]; then
  log "Everything checks out."
else
  err "$problems item(s) need attention."
  exit 1
fi
