#!/usr/bin/env bash
# Boot the kernel/initrd contained in the graphical ISO without relying on
# a graphical GRUB menu to write to the serial port.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="${1:-$ROOT/build/identos-live-amd64.iso}"
[[ -f "$ISO" && -s "$ISO" && ! -L "$ISO" ]] || { echo "ISO missing: $ISO" >&2; exit 2; }
for bin in qemu-system-x86_64 xorriso timeout; do
  command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 2; }
done
mkdir -p "$ROOT/build"
WORK="$(mktemp -d "$ROOT/build/qemu-kernel.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
LOG="$ROOT/build/graphics-boot.log"
xorriso -osirrox on -indev "$ISO" -extract /live "$WORK/live" >"$WORK/extract.log" 2>&1 || {
  cat "$WORK/extract.log" >&2; exit 1;
}
KERNEL="$(find "$WORK/live" -maxdepth 1 -type f \( -name 'vmlinuz*' -o -name 'linux*' \) | head -1)"
INITRD="$(find "$WORK/live" -maxdepth 1 -type f -name 'initrd*' | head -1)"
[[ -n "$KERNEL" && -n "$INITRD" ]] || { echo "Missing kernel or initrd in live ISO" >&2; exit 1; }
set +e
timeout 110s qemu-system-x86_64 -machine q35 -m 3072 -smp 2 \
  -kernel "$KERNEL" -initrd "$INITRD" \
  -append 'boot=live components console=ttyS0,115200n8 loglevel=6' \
  -display none -monitor none -serial stdio -nic none >"$LOG" 2>&1
status=$?
set -e
if [[ "$status" != 124 && "$status" != 0 ]]; then
  cat "$LOG"; echo "QEMU exited unexpectedly ($status)" >&2; exit 1
fi
if ! grep -Eiq 'Linux version|systemd\[1\]|Debian GNU/Linux|Starting.*[Ss]ystem' "$LOG"; then
  cat "$LOG"; echo 'No Linux boot evidence on serial console' >&2; exit 1
fi
echo 'PASS: graphical ISO kernel reached Linux serial boot.'
echo 'NOTE: GRUB, graphical login and browser require separate interactive checks.'
