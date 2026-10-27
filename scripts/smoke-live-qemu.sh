#!/usr/bin/env bash
# Gives the ISO 100 seconds to prove it can survive QEMU.
# No, surviving QEMU doesn't make it a finished desktop. Nice try.
set -euo pipefail
cd "$(dirname "$0")/.."
ISO="${ISO:-build/identos-live-amd64.iso}"
[[ -s "$ISO" ]] || { echo "ERROR: missing $ISO" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo 'ERROR: qemu-system-x86_64 required' >&2; exit 1; }
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
set +e
timeout 100s qemu-system-x86_64 -machine pc -m 2048 -smp 2 -cdrom "$ISO" \
  -boot d -nic none -display none -serial file:"$LOG" -no-reboot </dev/null >/dev/null 2>&1
status=$?
set -e
if [[ "$status" != 124 && "$status" != 0 ]]; then
  echo "QEMU exited unexpectedly: $status" >&2
  tail -80 "$LOG" >&2
  exit 1
fi
# No fake victory lap: a quiet serial console proves very little.
echo 'QEMU ran the ISO without crashing the emulator.'
echo 'NOTE: this is a virtual-machine launch check, not a desktop-login assertion.'
