#!/bin/sh
# Read-only hardware inventory for diagnosing an IDENT OS live session.
set -eu
printf 'IDENT OS | local system report\n'
printf 'UTC date: '; date -u '+%Y-%m-%dT%H:%M:%SZ'
printf 'Kernel: '; uname -sr
printf 'Architecture: '; uname -m
printf 'Uptime seconds: '; cut -d ' ' -f 1 /proc/uptime
printf '\nMemory (KiB):\n'
awk '/^(MemTotal|MemAvailable|SwapTotal):/ {print}' /proc/meminfo
printf '\nBlock devices (read-only):\n'
if command -v lsblk >/dev/null 2>&1; then lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS; fi
printf '\nGraphics devices:\n'
if command -v lspci >/dev/null 2>&1; then lspci | grep -Ei 'VGA|Display|3D' || true; fi
printf '\nSystem boot timing:\n'
if command -v systemd-analyze >/dev/null 2>&1; then systemd-analyze time 2>/dev/null || true; fi
printf '\nNo telemetry uploaded. Report contains hardware identifiers; review before sharing.\n'
