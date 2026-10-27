#!/usr/bin/env bash
# Check for a real bootable ISO, not just a file with an optimistic extension.
set -euo pipefail
ISO="${1:-build/identos-live-amd64.iso}"
[[ -s "$ISO" ]] || { echo "Missing or empty ISO: $ISO" >&2; exit 1; }
command -v xorriso >/dev/null || { echo "xorriso is required" >&2; exit 1; }
info="$(xorriso -indev "$ISO" -report_el_torito plain 2>&1)"
grep -qi 'El Torito' <<< "$info" || { echo 'No El Torito boot information' >&2; exit 1; }
if ! grep -qiE 'boot img|boot image' <<< "$info"; then
  echo 'No recorded boot image' >&2; exit 1
fi
echo 'PASS: optical-media boot catalog detected'
echo 'NOTE: this validates boot metadata, not a graphical desktop login.'
