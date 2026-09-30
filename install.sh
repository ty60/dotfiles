#!/usr/bin/env bash
# One-shot, idempotent dotfiles installer.
# Creates symlinks from $HOME into this repository. Safe to re-run.
#
# Usage:
#   ./install.sh          # full setup (MacBook Pro: the main dev machine)
#   ./install.sh --neo    # thin-client setup (MacBook Neo: SSHes into the Pro)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROFILE=full
case "${1:-}" in
  "") ;;
  --neo) PROFILE=neo ;;
  *) echo "usage: $0 [--neo]" >&2; exit 1 ;;
esac

# "repo path : link target" — repo path is relative to this directory.
# Linked on every machine: local shell, terminal and desktop setup.
COMMON_LINKS=(
  "shell/bashrc:$HOME/.bashrc"
  "shell/bash_profile:$HOME/.bash_profile"
  "shell/zshrc:$HOME/.zshrc"
  "shell/profile:$HOME/.profile"
  "shell/inputrc:$HOME/.inputrc"
  "ghostty/config:$HOME/.config/ghostty/config"
  "hammerspoon:$HOME/.hammerspoon"
)

# Linked only on the full setup: tools that run on the dev machine itself.
FULL_LINKS=(
  "tmux/tmux.conf:$HOME/.tmux.conf"
  "nvim:$HOME/.config/nvim"
  "brew/Brewfile:$HOME/.Brewfile"
  "claude/settings.json:$HOME/.claude/settings.json"
  "claude/scripts:$HOME/.claude/scripts"
  "herdr/config.toml:$HOME/.config/herdr/config.toml"
)

# Linked only on the Neo.
NEO_LINKS=(
  "brew/Brewfile.neo:$HOME/.Brewfile"
)

link() {
  local src="$DOTFILES/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
}

if [[ "$PROFILE" == neo ]]; then
  LINKS=("${COMMON_LINKS[@]}" "${NEO_LINKS[@]}")
else
  LINKS=("${COMMON_LINKS[@]}" "${FULL_LINKS[@]}")
fi

for entry in "${LINKS[@]}"; do
  link "${entry%%:*}" "${entry#*:}"
done

echo "Done ($PROFILE). Restart your shell or run: source ~/.bash_profile"
echo "Install packages with: brew bundle install --global"
