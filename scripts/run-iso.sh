#!/usr/bin/env bash
# Spin up the ISO in QEMU. Keep the data disk between boots.
set -euo pipefail

cd "$(dirname "$0")/.."
ISO="${ISO:-build/identos-dev-x86_64.iso}"
DISK="${DISK:-build/identos-data.ext4}"

if [[ ! -s "$ISO" ]]; then
  echo "ERROR: ISO missing: $ISO (run build-iso.sh)" >&2
  exit 1
fi

if ! command -v qemu-system-x86_64 >/dev/null; then
  echo 'ERROR: qemu-system-x86_64 missing' >&2
  exit 1
fi

if [[ ! -e "$DISK" ]]; then
  if ! command -v mkfs.ext4 >/dev/null; then
    echo 'ERROR: mkfs.ext4 missing' >&2
    exit 1
  fi

  mkdir -p "$(dirname "$DISK")"
  truncate -s 256M "$DISK"
  mkfs.ext4 -F -q "$DISK"
  echo "Created $DISK (256 MiB). Preserve this file to retain /data."
fi

# No network by default. This is a boot test, not a browsing session.
exec qemu-system-x86_64 -machine pc -m 768M -smp 2 -no-reboot \
  -cdrom "$ISO" -boot d \
  -drive "file=$DISK,format=raw,if=virtio" \
  -display none -serial mon:stdio -nic none
