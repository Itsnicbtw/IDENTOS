#!/usr/bin/env bash
# Headless boot check for the *graphical* ISO.
# This checks Linux boot progress, not whether a human can use the desktop.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$ROOT/build/identos-live-amd64.iso}"
[[ -s "$ISO" && -f "$ISO" && ! -L "$ISO" ]] || { echo "ISO missing: $ISO" >&2; exit 2; }
command -v qemu-system-x86_64 >/dev/null || { echo 'QEMU missing' >&2; exit 2; }
LOG="$ROOT/build/graphics-boot.log"
mkdir -p "$ROOT/build"
set +e
timeout 110s qemu-system-x86_64 -machine q35 -m 3072 -smp 2 -boot d \
  -cdrom "$ISO" -display none -monitor none -serial stdio \
  -device virtio-vga -nic none >"$LOG" 2>&1
status=$?
set -e
# A timeout is expected: a live system should not exit after boot.
if [[ "$status" != 124 && "$status" != 0 ]]; then
  cat "$LOG"
  echo "QEMU exited unexpectedly ($status)" >&2
  exit 1
fi
if ! grep -Eiq 'Linux version|systemd\[1\]|Debian GNU/Linux|Starting.*[Ss]ystem' "$LOG"; then
  cat "$LOG"
  echo 'No Linux boot evidence on serial console' >&2
  exit 1
fi
echo "PASS: graphical live image reached Linux boot messages."
echo "NOTE: graphical login, compositor and browser still require interactive verification."
