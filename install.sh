#!/usr/bin/env bash
# One-shot, idempotent dotfiles installer.
# Creates symlinks from $HOME into this repository. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# "repo path : link target" — repo path is relative to this directory.
LINKS=(
  "shell/bashrc:$HOME/.bashrc"
  "shell/bash_profile:$HOME/.bash_profile"
  "shell/zshrc:$HOME/.zshrc"
  "shell/profile:$HOME/.profile"
  "shell/inputrc:$HOME/.inputrc"
  "tmux/tmux.conf:$HOME/.tmux.conf"
  "nvim:$HOME/.config/nvim"
  "claude/settings.json:$HOME/.claude/settings.json"
  "claude/scripts:$HOME/.claude/scripts"
)

link() {
  local src="$DOTFILES/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
}

for entry in "${LINKS[@]}"; do
  link "${entry%%:*}" "${entry#*:}"
done

echo "Done. Restart your shell or run: source ~/.bash_profile"
