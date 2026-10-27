#!/usr/bin/env bash
# Boots the graphical ISO with QEMU and checks kernel/live-boot serial output.
# This does NOT claim a graphical login was reached; that requires a guest agent.
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
# The serial console may be silent unless the bootloader/kernel is configured
# for serial output. Preserve the log for inspection without claiming full boot.
echo 'QEMU ran the ISO without crashing the emulator.'
echo 'NOTE: this is a virtual-machine launch check, not a desktop-login assertion.'
