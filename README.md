# dotfiles

Personal dotfiles for an [Omarchy](https://omarchy.org/) system, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's included

| Package | Tracks |
|---|---|
| `bash` | `.bashrc`, `.bash_profile`, `.bash_logout`, `.profile` |
| `zsh` | `.zshrc` |
| `git` | `.config/git/config` |
| `nvim` | `.config/nvim/` |
| `tmux` | `.config/tmux/` |
| `hypr` | `.config/hypr/` (Hyprland — all config files) |
| `omarchy` | `.config/omarchy/` (themes, hooks, extensions, branding) |
| `waybar` | `.config/waybar/` |
| `walker` | `.config/walker/` |
| `mako` | `.config/mako/` |
| `alacritty` | `.config/alacritty/` |
| `ghostty` | `.config/ghostty/` |
| `kitty` | `.config/kitty/` |
| `lazygit` | `.config/lazygit/` |
| `btop` | `.config/btop/` |
| `fastfetch` | `.config/fastfetch/` |
| `starship` | `.config/starship.toml` |

The `ghost-pastel` Omarchy theme is tracked as a git submodule pointing to its [original repo](https://github.com/row-huh/omarchy-ghost-pastel-theme).

## Fresh install

```bash
# 1. Clone (including submodules)
git clone --recurse-submodules https://github.com/tiddez/dotfiles.git ~/.dotfiles

# 2. Install GNU Stow if not present
sudo pacman -S stow

# 3. Stow all packages
cd ~/.dotfiles
stow bash zsh git nvim tmux hypr omarchy alacritty ghostty kitty waybar walker mako lazygit btop fastfetch starship
```

> If a target file already exists and is not a symlink, stow will error.
> Back it up first: `cp ~/.bashrc ~/.bashrc.bak` then delete the original before stowing.

## Daily use

Changes you make directly to your config files (e.g. editing `~/.config/hypr/looknfeel.conf`) are immediately reflected in the repo because they are symlinks into `~/.dotfiles/`.

To save and push changes:

```bash
cd ~/.dotfiles
git add -p          # review what changed
git commit -m "..."
git push
```

## Adding a new dotfile

### Single file in `~/`

```bash
mkdir -p ~/.dotfiles/foo
mv ~/.foorc ~/.dotfiles/foo/.foorc
cd ~/.dotfiles && stow foo
```

### Directory in `~/.config/`

```bash
mkdir -p ~/.dotfiles/foo/.config
mv ~/.config/foo ~/.dotfiles/foo/.config/foo
cd ~/.dotfiles && stow foo
```

Then commit:

```bash
cd ~/.dotfiles
git add foo
git commit -m "Add foo dotfiles"
git push
```

## Removing a package

To unlink a package without deleting the files:

```bash
cd ~/.dotfiles
stow -D foo
```

This removes the symlinks and restores nothing — the files stay safely in `~/.dotfiles/foo/`.

## Updating submodules

```bash
cd ~/.dotfiles
git submodule update --remote --merge
git add omarchy/.config/omarchy/themes/ghost-pastel
git commit -m "Update ghost-pastel theme"
git push
```
