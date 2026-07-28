#!/usr/bin/env bash
# Self-check for install_file's backup pruning. No framework on purpose.
# Run it after touching lib/common.sh.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/repo" "$tmp/home"

fail() { err "$*"; exit 1; }
count_backups() { find "$tmp/home" -maxdepth 1 -name 'zshrc.bak.*' | wc -l | tr -d ' '; }

echo "v1"          > "$tmp/home/zshrc"
echo "old backup"  > "$tmp/home/zshrc.bak.20200101000000"
echo "neighbour"   > "$tmp/home/zshrc.other"
echo "sibling bak" > "$tmp/home/zprofile.bak.20200101000000"
echo "v2"          > "$tmp/repo/zshrc"

install_file "$tmp/repo/zshrc" "$tmp/home/zshrc" >/dev/null 2>&1
[ "$(count_backups)" = "1" ] || fail "expected exactly 1 backup, got $(count_backups)"
grep -qx "v1" "$(find "$tmp/home" -maxdepth 1 -name 'zshrc.bak.*')" \
  || fail "the surviving backup is not the previous content"
grep -qx "v2" "$tmp/home/zshrc" || fail "destination was not replaced"
[ -f "$tmp/home/zshrc.other" ] || fail "deleted a neighbouring file"
[ -f "$tmp/home/zprofile.bak.20200101000000" ] || fail "deleted another file's backup"

install_file "$tmp/repo/zshrc" "$tmp/home/zshrc" >/dev/null 2>&1
[ "$(count_backups)" = "1" ] || fail "a no-op run changed the backups"

log "ok — install_file keeps one backup and touches nothing else"
