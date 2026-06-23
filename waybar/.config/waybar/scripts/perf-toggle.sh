#!/bin/bash
set -euo pipefail

profile=$(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo unknown)
on_ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1 || echo 0)

if [[ "$profile" == "performance" ]]; then
  if [[ "$on_ac" == "1" ]]; then
    sudo /usr/bin/tlp auto >/dev/null
    label="Plugged in — back to AC auto"
  else
    sudo /usr/bin/tlp bat >/dev/null
    label="On battery — normal profile"
  fi
  notify-send -t 2000 "Performance mode: off" "$label" 2>/dev/null || true
else
  sudo /usr/bin/tlp ac >/dev/null
  notify-send -t 2000 "Performance mode: on" "Forcing AC profile" 2>/dev/null || true
fi
