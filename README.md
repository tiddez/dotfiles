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
git clone https://github.com/tiddez/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./backup.sh   # backs up existing configs to /tmp/.config_bkps_<timestamp>, then removes them
./install.sh  # installs stow if needed, then symlinks everything
```

`backup.sh` checks every file and directory that stow would conflict with. If it finds a real file, it copies it to a timestamped folder in `/tmp` and removes the original. Existing symlinks (already stowed) are skipped. After it runs, stow has a clean path.

`install.sh` clones the repo if it isn't already present, initialises submodules, and runs `stow` for all packages.

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
