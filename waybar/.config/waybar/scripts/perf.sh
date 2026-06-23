#!/bin/bash
p=$(powerprofilesctl get 2>/dev/null || cat /sys/firmware/acpi/platform_profile 2>/dev/null)
case "$p" in
  performance)       printf '󰓅 PERF' ;;
  low-power|cool|quiet) printf '󰌪 ECO'  ;;
  balanced|"")       printf ''       ;;
  *)                 printf '%s' "$p" ;;
esac
