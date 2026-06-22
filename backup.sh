#!/usr/bin/env bash
# Backs up existing config files that would conflict with stow, then removes them.
# Run this before install.sh on a new machine.
set -euo pipefail

BACKUP_DIR="/tmp/.config_bkps_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

backup_and_remove() {
  local target="$1"
  local rel="${target#$HOME/}"  # path relative to ~

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local dest="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -r "$target" "$dest"
    rm -rf "$target"
    echo "  backed up + removed: ~/$rel"
  elif [ -L "$target" ]; then
    echo "  skipped (already a symlink): ~/$rel"
  else
    echo "  not found, nothing to do: ~/$rel"
  fi
}

echo "==> Backing up and removing conflicting files to: $BACKUP_DIR"
echo ""

# Shell files
backup_and_remove "$HOME/.bashrc"
backup_and_remove "$HOME/.bash_profile"
backup_and_remove "$HOME/.bash_logout"
backup_and_remove "$HOME/.profile"
backup_and_remove "$HOME/.zshrc"

# .config entries
for dir in git nvim tmux hypr omarchy alacritty ghostty kitty waybar walker mako lazygit btop fastfetch; do
  backup_and_remove "$HOME/.config/$dir"
done

# Single file in .config
backup_and_remove "$HOME/.config/starship.toml"

echo ""
echo "Done. Backup saved to: $BACKUP_DIR"
echo "You can now run ./install.sh"
