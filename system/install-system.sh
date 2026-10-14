#!/usr/bin/env bash
# Installs the system-level tuning for the Dell Latitude 7400 (outside $HOME,
# so it is NOT handled by stow — files are copied, not symlinked):
#   - intel-undervolt: CPU/Cache -90 mV, GPU -60 mV   (/etc/intel-undervolt.conf)
#   - CPU power limits 15 W / 30 W, at boot and after resume (power-limits.service)
#   - battery charge limit 75% -> 80% (stored in the Dell BIOS)
# Details and how to undo: README.md in this folder.
#
# Usage: sudo ./install-system.sh
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Undervolt values are tuned for this specific CPU (i7-8665U). On another
# machine they may crash it, so refuse unless forced.
MODEL="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo unknown)"
if [ "$MODEL" != "Latitude 7400" ] && [ "${FORCE:-0}" != "1" ]; then
  echo "This tuning is for a Dell Latitude 7400 (this machine: $MODEL)." >&2
  echo "Re-run with FORCE=1 to install anyway." >&2
  exit 1
fi

echo "==> intel-undervolt package"
if ! command -v intel-undervolt &>/dev/null; then
  pacman -S --needed --noconfirm intel-undervolt
fi

echo "==> Undervolt config (/etc/intel-undervolt.conf)"
if [ -f /etc/intel-undervolt.conf ] && ! cmp -s "$DIR/etc/intel-undervolt.conf" /etc/intel-undervolt.conf; then
  cp /etc/intel-undervolt.conf "/etc/intel-undervolt.conf.bak-$(date +%Y%m%d-%H%M%S)"
fi
install -m 644 "$DIR/etc/intel-undervolt.conf" /etc/intel-undervolt.conf

echo "==> Power limits (script + systemd service)"
install -m 755 "$DIR/usr/local/bin/set-power-limits" /usr/local/bin/set-power-limits
install -m 644 "$DIR/etc/systemd/system/power-limits.service" /etc/systemd/system/power-limits.service

systemctl daemon-reload
systemctl enable intel-undervolt.service
systemctl enable power-limits.service

echo "==> Applying now"
intel-undervolt apply
systemctl restart power-limits.service

echo "==> Battery charge limit 75% -> 80% (saved in the Dell BIOS)"
B=/sys/class/power_supply/BAT0
if [ -w "$B/charge_control_end_threshold" ]; then
  echo Custom > "$B/charge_types" 2>/dev/null || true
  # Dell needs end >= start + 5 at every step: raise the end first, then set start, then lower the end.
  echo 100 > "$B/charge_control_end_threshold"
  echo 75  > "$B/charge_control_start_threshold"
  echo 80  > "$B/charge_control_end_threshold"
else
  echo "   (charge thresholds not available on this machine — skipped)"
fi

R=/sys/class/powercap/intel-rapl:0
echo ""
echo "Done:"
echo "  power limits : PL1=$(( $(cat $R/constraint_0_power_limit_uw)/1000000 ))W PL2=$(( $(cat $R/constraint_1_power_limit_uw)/1000000 ))W"
[ -r "$B/charge_control_end_threshold" ] && \
  echo "  battery      : $(cat $B/charge_control_start_threshold)% -> $(cat $B/charge_control_end_threshold)% ($(cat $B/charge_types))"
echo "  services     : intel-undervolt=$(systemctl is-enabled intel-undervolt.service) power-limits=$(systemctl is-enabled power-limits.service)"
