#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n scripts/build-initramfs.sh scripts/run-qemu.sh scripts/test.sh scripts/smoke-qemu.sh scripts/build-live-iso.sh
for browser in firefox chrome tor aster; do
  grep -Fq "ident.browser=$browser" scripts/build-iso.sh
  grep -Fq "ident.browser=$browser" rootfs/init
done
bash -n scripts/build-live-iso.sh
for marker in 'task-xfce-desktop' 'lightdm' 'firefox-esr' 'identos-browser' 'xserver-xorg-input-libinput'; do
  grep -Fq "$marker" scripts/build-live-iso.sh
done
sh -n assets/identos-egg
for egg in help fortune coffee corporate sudo secret all; do
  sh assets/identos-egg "$egg" >/dev/null
done
if sh assets/identos-egg bogus >/dev/null 2>&1; then
  echo 'ERROR: unknown Easter egg unexpectedly succeeded' >&2
  exit 1
fi
if command -v busybox >/dev/null; then busybox sh -n rootfs/init; else sh -n rootfs/init; fi
./scripts/build-initramfs.sh
image=build/identos-initramfs.cpio.gz
test -s "$image"
gzip -t "$image"
listing="$(gzip -dc "$image" | cpio -t 2>/dev/null)"
for path in init bin/busybox bin/sh bin/nano bin/python3 bin/node bin/git bin/gcc bin/g++ bin/make bin/curl bin/tar etc/identos-runtime usr/share/terminfo/v/vt100; do
  if ! grep -Fxq "$path" <<< "$listing" && ! grep -Fxq "./$path" <<< "$listing"; then
    echo "ERROR: initramfs missing $path" >&2
    exit 1
  fi
done
if ! grep -Eq '^(\./)?(usr/)?bin/npm$' <<< "$listing"; then
  echo 'ERROR: initramfs missing npm executable' >&2
  exit 1
fi
printf 'PASS: shell syntax, image generation and archive contents\n'
