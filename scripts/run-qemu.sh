#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
KERNEL="${KERNEL:-/boot/vmlinuz-$(uname -r)}"
IMAGE=build/identos-initramfs.cpio.gz
[[ -f "$KERNEL" ]] || { echo "ERROR: Kernel not found at $KERNEL. Set KERNEL=/path/to/bzImage" >&2; exit 1; }
[[ -f "$IMAGE" ]] || { echo 'ERROR: Build initramfs first: ./scripts/build-initramfs.sh' >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo 'ERROR: Install qemu-system-x86' >&2; exit 1; }
exec qemu-system-x86_64 \
  -machine q35 -m 512M -smp 2 -no-reboot \
  -kernel "$KERNEL" -initrd "$IMAGE" \
  -append 'console=ttyS0 rdinit=/init panic=1' \
  -nographic -nic none
