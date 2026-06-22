#!/usr/bin/env bash
# Sets up dotfiles on a new machine using GNU Stow.
# Run backup.sh first if config files already exist.
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
REPO="https://github.com/tiddez/dotfiles.git"
PACKAGES=(bash zsh git nvim tmux hypr omarchy alacritty ghostty kitty waybar walker mako lazygit btop fastfetch starship)

# Install stow if missing
if ! command -v stow &>/dev/null; then
  echo "==> Installing stow..."
  sudo pacman -S --noconfirm stow
fi

# Clone repo if not already present
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "==> Cloning dotfiles..."
  git clone --recurse-submodules "$REPO" "$DOTFILES_DIR"
else
  echo "==> ~/.dotfiles already present, updating submodules..."
  git -C "$DOTFILES_DIR" submodule update --init --recursive
fi

# Stow all packages
echo "==> Stowing packages..."
cd "$DOTFILES_DIR"
stow --target="$HOME" "${PACKAGES[@]}"

echo ""
echo "Done. All dotfiles are linked."
