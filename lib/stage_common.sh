#!/usr/bin/env bash
# Stage shared by both operating systems. Source after lib/common.sh.
# Everything here is install-if-missing, upgrade-if-present.

# Old-model symlinks pointed into the repo and turned into dangling files once it moved.
# Backing one up produced a *.bak.* that is itself a symlink into the repo: drop those too.
clean_legacy_links() {
  local n=0 dest f
  while IFS='|' read -r _ dest; do
    [ -n "$dest" ] || continue
    while IFS= read -r f; do
      rm -f "$f"; n=$((n + 1))
    done < <(find "$(dirname "$dest")" -maxdepth 1 -type l \
               -name "$(basename "$dest").bak.*" 2>/dev/null)
  done < <(dotfiles_map)
  [ "$n" -gt 0 ] && log "removed $n legacy symlink backups"
  return 0
}

read_list() {
  grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || true
}

install_configs() {
  log "Configs (copied to the machine)"
  clean_legacy_links
  mkdir -p "$SHELL_CONFIG_DIR"
  while IFS='|' read -r rel dest; do
    [ -n "$rel" ] || continue
    install_file "$DOTFILES_DIR/$rel" "$dest"
  done < <(dotfiles_map)
}

# ~/.bashrc is the distro's file, not ours, so this is the one config that gets appended
# to rather than copied over. Without it a bash session has no Homebrew on PATH and every
# `brew` call opens with a warning — and bash is still what scripts, editors and IDE
# terminals run, whatever the login shell is.
BASH_HOOK_MARKER="# >>> dotfiles >>>"
install_bash_hook() {
  local rc="$HOME/.bashrc"
  [ -f "$rc" ] || return 0
  grep -qF "$BASH_HOOK_MARKER" "$rc" && return 0
  log "Hooking ~/.bashrc into the shared shell config"
  cat >> "$rc" <<EOF

$BASH_HOOK_MARKER
# Managed by dotfiles. Same environment the zsh side gets; remove this block to opt out.
for _f in brew env aliases; do
  [ -r "\$HOME/.config/shell/\$_f.sh" ] && . "\$HOME/.config/shell/\$_f.sh"
done
unset _f
# <<< dotfiles <<<
EOF
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh: updating"
    ZSH="$HOME/.oh-my-zsh" sh "$HOME/.oh-my-zsh/tools/upgrade.sh" >/dev/null 2>&1 \
      || warn "oh-my-zsh update failed"
    return 0
  fi
  log "Oh My Zsh: installing"
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_node() {
  export NVM_DIR="$HOME/.nvm"
  [ -d "$NVM_DIR" ] || mkdir -p "$NVM_DIR"
  # shellcheck disable=SC1091
  [ -s "$(brew_prefix)/opt/nvm/nvm.sh" ] && . "$(brew_prefix)/opt/nvm/nvm.sh"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  command_exists nvm || { warn "nvm unavailable; skipped Node"; return 0; }
  log "Node: latest LTS"
  nvm install --lts
  nvm alias default 'lts/*' >/dev/null
}

# Without a version installed, rbenv sits there inert and `ruby` silently falls back
# to the system copy.
install_ruby() {
  command_exists rbenv || { warn "rbenv missing; skipped Ruby"; return 0; }
  if [ -n "$(rbenv versions --bare 2>/dev/null)" ]; then
    log "Ruby: $(rbenv global 2>/dev/null) already installed"
    return 0
  fi
  local latest
  latest="$(rbenv install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)"
  [ -n "$latest" ] || { warn "could not resolve a Ruby version; skipped"; return 0; }
  log "Ruby: installing $latest (compiles, takes a few minutes)"
  rbenv install -s "$latest" || { warn "ruby $latest failed to build"; return 0; }
  rbenv global "$latest"
  rbenv rehash
}

install_bun() {
  if command_exists bun; then
    log "Bun: updating"
    bun upgrade >/dev/null 2>&1 || warn "bun upgrade failed"
    return 0
  fi
  log "Bun: installing"
  curl -fsSL https://bun.sh/install | bash || warn "bun install failed"
}

# env.sh exports PNPM_HOME and puts it on PATH, but nothing creates it: brew's pnpm
# leaves it to `pnpm setup`, which would rewrite the shell rc files this repo owns.
# Mirrors the per-OS path in shell/env.sh.
ensure_runtime_dirs() {
  if [ "$(uname -s)" = "Darwin" ]; then
    mkdir -p "$HOME/Library/pnpm"
  else
    mkdir -p "$HOME/.local/share/pnpm"
  fi
  mkdir -p "$HOME/.local/bin"
}

install_npm_globals() {
  command_exists npm || { warn "npm missing; skipped globals"; return 0; }
  local pkg
  log "npm globals"
  # </dev/null: npm reads stdin and would eat the list being iterated.
  while read -r pkg; do
    npm install -g "$pkg@latest" >/dev/null 2>&1 </dev/null || warn "npm failed: $pkg"
  done < <(read_list "$DOTFILES_DIR/packages/npm-global.txt")
}

install_vscode_exts() {
  local cli ext
  cli="$(vscode_cli)" || { warn "VS Code CLI missing; skipped extensions"; return 0; }
  log "VS Code extensions"
  while read -r ext; do
    "$cli" --install-extension "$ext" --force >/dev/null 2>&1 </dev/null \
      || warn "extension failed: $ext"
  done < <(read_list "$DOTFILES_DIR/packages/vscode-extensions.txt")
}

# Claude Code and Copilot CLI come from npm-global.txt; this is the gh extension.
install_gh_copilot() {
  command_exists gh || { warn "gh missing; skipped copilot extension"; return 0; }
  if gh extension list 2>/dev/null | grep -q 'github/gh-copilot'; then
    gh extension upgrade github/gh-copilot >/dev/null 2>&1 || true
    return 0
  fi
  log "gh copilot extension"
  gh extension install github/gh-copilot >/dev/null 2>&1 \
    || warn "gh copilot failed (run gh auth login first)"
}

set_default_shell() {
  local zsh_bin; zsh_bin="$(command -v zsh)"
  [ -z "$zsh_bin" ] && return 0
  [ "${SHELL:-}" = "$zsh_bin" ] && return 0
  log "Setting zsh as the default shell (may ask for your password)"
  grep -qx "$zsh_bin" /etc/shells 2>/dev/null || \
    echo "$zsh_bin" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$zsh_bin" || warn "chsh failed; change it manually"
}

run_common_stage() {
  install_oh_my_zsh
  install_configs
  install_bash_hook
  ensure_runtime_dirs
  install_node
  install_ruby
  install_bun
  install_npm_globals
  install_vscode_exts
  install_gh_copilot
  set_default_shell
  log "Common stage done"
}
