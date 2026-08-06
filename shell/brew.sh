# shellcheck shell=sh
# ~/.config/shell/brew.sh — managed by dotfiles (copied, not symlinked).
# Edited the repo? run ./install.sh --configs-only. Edited this file? run ./sync.sh.
#
# The one place that knows where Homebrew lives. It used to be spelled out in ~/.zprofile,
# in env.sh and in lib/common.sh, which is three chances for the list to drift apart.
#
#   /opt/homebrew ............... macOS, Apple Silicon
#   /usr/local .................. macOS, Intel
#   /home/linuxbrew/.linuxbrew .. Linux
#
# Same Homebrew in all three; only the prefix differs. "Linuxbrew" was a separate fork
# years ago and the name stuck to the path, but `brew` is `brew` everywhere now.
#
# Plain sh, no bashisms and no zsh-isms: ~/.zprofile, env.sh and ~/.bashrc all source it.
if ! command -v brew >/dev/null 2>&1; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$_brew" ]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi
