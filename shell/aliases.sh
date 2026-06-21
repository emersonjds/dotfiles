#!/usr/bin/env bash
# Aliases cross-platform.

alias pip="pip3"

if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lah --icons --group-directories-first --git"
  alias lt="eza --tree --level=2 --icons"
fi
