#!/usr/bin/env bash
# Boot self-contained IDENT initrd in headless QEMU, no drive passthrough.
set -euo pipefail
KERNEL="${1:?Usage: boot-qemu.sh KERNEL INITRD}"
INITRD="${2:?Usage: boot-qemu.sh KERNEL INITRD}"
[[ -f "$KERNEL" && ! -L "$KERNEL" && -f "$INITRD" && ! -L "$INITRD" ]] || { echo 'Kernel and initrd must be regular files' >&2; exit 2; }
command -v qemu-system-x86_64 >/dev/null || { echo 'Missing qemu-system-x86_64' >&2; exit 2; }
exec qemu-system-x86_64 -machine q35 -m 512 -smp 1 -no-reboot -display none -serial stdio -monitor none -nic none -nodefaults -kernel "$KERNEL" -initrd "$INITRD" -append 'console=ttyS0,115200n8 rdinit=/init'
