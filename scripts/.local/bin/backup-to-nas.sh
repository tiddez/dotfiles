#!/bin/bash
#
# backup-to-nas.sh — back up this laptop's home directory to the NAS over SMB.
#
# USAGE
#   backup-to-nas.sh                # normal run: copy new/changed files (rsync
#                                    # only transfers what's different, so this
#                                    # IS the "differential" backup after the
#                                    # first run — nothing special to invoke)
#   backup-to-nas.sh --dry-run       # show what would be copied/removed, no changes
#   backup-to-nas.sh --prune         # also delete files on the NAS that no longer
#                                    # exist locally (true mirror). Off by default
#                                    # on purpose: a plain run never deletes your
#                                    # backup, so an accidental local delete can't
#                                    # wipe the copy too.
#   backup-to-nas.sh --dry-run --prune   # preview exactly what --prune would delete
#
# WHAT IT DOES
#   1. Mounts //192.168.50.20/media-archive over CIFS (using ~/.smbcredentials)
#   2. rsyncs /home/bbsa -> media-archive/Leonardo/Backup pc/Laptop/home/bbsa
#   3. Dumps an installed-package list (pacman + AUR) next to it, so a fresh
#      Omarchy install can restore the same packages
#   4. Writes a timestamped log under .../Laptop/logs/
#   5. Unmounts the share again (only if this script mounted it)
#
# FIRST-TIME SETUP
#   ~/.smbcredentials must exist, mode 600, containing:
#     username=<smb-user>
#     password=<smb-password>
#     domain=WORKGROUP
#
# RESTORE (e.g. after a fresh install)
#   sudo mkdir -p /mnt/backup-nas
#   sudo mount -t cifs //192.168.50.20/media-archive /mnt/backup-nas \
#       -o credentials=$HOME/.smbcredentials,uid=$(id -u),gid=$(id -g),vers=3.0
#   rsync -aAXH --info=progress2 \
#       "/mnt/backup-nas/Leonardo/Backup pc/Laptop/home/bbsa/" "$HOME/"
#   sudo umount /mnt/backup-nas
#   Then reinstall packages: sudo pacman -S --needed - < packages-pacman.txt
#                             yay -S --needed - < packages-aur.txt

set -euo pipefail

# Run this as your normal user, NOT with sudo — the script escalates itself
# only for the mount step. If it's accidentally run under sudo anyway,
# fall back to the invoking (non-root) user's home so paths stay correct.
if [[ "$EUID" == 0 && -n "${SUDO_USER:-}" ]]; then
  REAL_USER="$SUDO_USER"
  REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
  REAL_USER="$(whoami)"
  REAL_HOME="$HOME"
fi

SERVER="192.168.50.20"
SHARE="//${SERVER}/media-archive"
SUBPATH="Leonardo/Backup pc/Laptop"
MOUNTPOINT="/mnt/backup-nas"
CREDFILE="$REAL_HOME/.smbcredentials"
SRC="$REAL_HOME/"
DEST_ROOT="$MOUNTPOINT/$SUBPATH"
DEST="$DEST_ROOT/home/$REAL_USER/"

DRY_RUN=0
PRUNE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --prune) PRUNE=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$CREDFILE" ]]; then
  echo "Missing $CREDFILE — create it first (see script header)." >&2
  exit 1
fi
if [[ "$(stat -c %a "$CREDFILE")" != "600" ]]; then
  echo "Warning: $CREDFILE should be chmod 600 (currently $(stat -c %a "$CREDFILE"))." >&2
fi

WE_MOUNTED=0
cleanup() {
  if [[ "$WE_MOUNTED" == "1" ]]; then
    echo "Unmounting $MOUNTPOINT..."
    sudo umount "$MOUNTPOINT" || echo "Warning: umount failed, unmount manually with: sudo umount $MOUNTPOINT" >&2
  fi
}
trap cleanup EXIT

sudo mkdir -p "$MOUNTPOINT"

if mountpoint -q "$MOUNTPOINT"; then
  echo "$MOUNTPOINT already mounted, reusing it."
else
  echo "Mounting $SHARE on $MOUNTPOINT..."
  sudo mount -t cifs "$SHARE" "$MOUNTPOINT" \
    -o "credentials=$CREDFILE,uid=$(id -u "$REAL_USER"),gid=$(id -g "$REAL_USER"),iocharset=utf8,vers=3.0,file_mode=0644,dir_mode=0755"
  WE_MOUNTED=1
fi

mkdir -p "$DEST_ROOT/home" "$DEST_ROOT/system-info" "$DEST_ROOT/logs"

echo "Exporting installed package lists..."
pacman -Qqe > "$DEST_ROOT/system-info/packages-pacman.txt"
pacman -Qqem > "$DEST_ROOT/system-info/packages-aur.txt" 2>/dev/null || true
{
  uname -a
  echo
  cat /etc/os-release
  echo
  omarchy version 2>/dev/null || true
} > "$DEST_ROOT/system-info/system-info.txt"

RSYNC_FLAGS=(-aAXH --info=progress2 --exclude=".smbcredentials")
if [[ "$DRY_RUN" == "1" ]]; then
  RSYNC_FLAGS+=(--dry-run)
  echo "DRY RUN — no files will actually be copied or deleted."
fi
if [[ "$PRUNE" == "1" ]]; then
  RSYNC_FLAGS+=(--delete-after)
  echo "PRUNE enabled — files removed locally will also be removed from the NAS copy."
fi

LOGFILE="$DEST_ROOT/logs/backup-$(date +%Y-%m-%d_%H%M).log"
echo "Backing up $SRC -> $DEST"
echo "Log: $LOGFILE"
rsync "${RSYNC_FLAGS[@]}" "$SRC" "$DEST" | tee "$LOGFILE"

echo "Done."
