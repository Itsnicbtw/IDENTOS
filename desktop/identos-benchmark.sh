#!/bin/sh
# IDENT OS performance baseline: measurements, not advertising.
set -eu
printf 'IDENT OS desktop performance snapshot\n'
printf 'Date: '; date -u '+%Y-%m-%dT%H:%M:%SZ'
printf 'Kernel: '; uname -sr
printf 'Uptime (seconds): '; cut -d ' ' -f 1 /proc/uptime
printf 'Memory available (KiB): '; awk '/^MemAvailable:/ {print $2}' /proc/meminfo
printf 'Memory total (KiB): '; awk '/^MemTotal:/ {print $2}' /proc/meminfo
printf 'Load averages: '; cat /proc/loadavg
if command -v systemd-analyze >/dev/null 2>&1; then
  printf '\nBoot timing (when systemd data is available):\n'
  systemd-analyze time 2>/dev/null || true
fi
if command -v ps >/dev/null 2>&1; then
  printf '\nDesktop processes (RSS KiB; best effort):\n'
  ps -eo comm,rss 2>/dev/null | awk '$1 ~ /^(openbox|python3|lightdm|Xorg|rofi|feh)$/ {print $1, $2}' || true
fi
printf '\nCompare on the same hardware and workload before claiming gains.\n'
