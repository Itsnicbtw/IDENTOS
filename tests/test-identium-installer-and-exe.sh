#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n independent/install-vm-image.sh independent/identium-run-exe scripts/build-live-iso.sh
sh -n independent/init independent/identium-run-exe
# Must reject all direct block-device destinations *before* checking dependencies.
if bash independent/install-vm-image.sh --kernel /dev/null --initrd /dev/null --rootfs /dev/null --output /dev/sda >/dev/null 2>&1; then
 echo 'FAIL: physical disk accepted' >&2; exit 1
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
: > "$work/existing.img"
if bash independent/install-vm-image.sh --kernel /dev/null --initrd /dev/null --rootfs /dev/null --output "$work/existing.img" >/dev/null 2>&1; then
 echo 'FAIL: existing output accepted' >&2; exit 1
fi
: > "$work/hello.exe"
mkdir "$work/bin"
cat > "$work/bin/wine" <<'STUB'
#!/bin/sh
printf '%s\n' "$1" "$2"
STUB
chmod +x "$work/bin/wine"
result="$(PATH="$work/bin:$PATH" sh independent/identium-run-exe "$work/hello.exe" 'a spaced argument')"
[[ "$result" == "$work/hello.exe"$'\n''a spaced argument' ]] || { echo 'Wine arguments mangled' >&2; exit 1; }
grep -Fq 'identium.persist=1' independent/init
grep -Fq 'wine64' scripts/build-live-iso.sh
grep -Fq 'identium-run-exe' scripts/build-live-iso.sh
echo 'PASS: physical-device refusal, output protection and EXE argument forwarding'
