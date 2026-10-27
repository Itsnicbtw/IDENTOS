#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n scripts/build-initramfs.sh scripts/run-qemu.sh scripts/test.sh
if command -v busybox >/dev/null; then busybox sh -n rootfs/init; else sh -n rootfs/init; fi
./scripts/build-initramfs.sh
test -s build/identos-initramfs.cpio.gz
gzip -t build/identos-initramfs.cpio.gz
for path in init bin/busybox bin/sh; do
  gzip -dc build/identos-initramfs.cpio.gz | cpio -t 2>/dev/null | grep -Fxq "$path" || {
    echo "ERROR: initramfs missing $path" >&2; exit 1;
  }
done
printf 'PASS: shell syntax, image generation and archive contents\n'
