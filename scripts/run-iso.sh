#!/usr/bin/env bash
# Run the IDENT OS ISO in QEMU with an optional persistent ext4 data drive.
set -euo pipefail
cd "$(dirname "$0")/.."
ISO="${ISO:-build/identos-dev-x86_64.iso}"
DISK="${DISK:-build/identos-data.ext4}"
[[ -s "$ISO" ]] || { echo "ERROR: ISO missing: $ISO (run build-iso.sh)" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo 'ERROR: qemu-system-x86_64 missing' >&2; exit 1; }
if [[ ! -e "$DISK" ]]; then
  command -v mkfs.ext4 >/dev/null || { echo 'ERROR: mkfs.ext4 missing' >&2; exit 1; }
  mkdir -p "$(dirname "$DISK")"
  truncate -s 256M "$DISK"
  mkfs.ext4 -F -q "$DISK"
  echo "Created $DISK (256 MiB). Preserve this file to retain /data."
fi
exec qemu-system-x86_64 -machine pc -m 768M -smp 2 -no-reboot \
  -cdrom "$ISO" -boot d \
  -drive "file=$DISK,format=raw,if=virtio" \
  -display none -serial mon:stdio -nic none
