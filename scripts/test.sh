#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n scripts/build-initramfs.sh scripts/run-qemu.sh scripts/test.sh scripts/smoke-qemu.sh
if command -v busybox >/dev/null; then busybox sh -n rootfs/init; else sh -n rootfs/init; fi
./scripts/build-initramfs.sh
image=build/identos-initramfs.cpio.gz
test -s "$image"
gzip -t "$image"
listing="$(gzip -dc "$image" | cpio -t 2>/dev/null)"
for path in init bin/busybox bin/sh; do
  if ! printf '%s\n' "$listing" | sed 's#^\\./##' | grep -Fxq "$path"; then
    echo "ERROR: initramfs missing $path" >&2
    exit 1
  fi
done
printf 'PASS: shell syntax, image generation and archive contents\n'
