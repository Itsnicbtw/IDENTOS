#!/usr/bin/env bash
# Convert verified IDENT rootfs archive to bootable initramfs, no disk writes.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE="${1:?Usage: build-initrd.sh ROOTFS.tar.gz OUTPUT.cpio.gz}"
OUT="${2:?Usage: build-initrd.sh ROOTFS.tar.gz OUTPUT.cpio.gz}"
[[ -f "$ARCHIVE" && ! -L "$ARCHIVE" && "$OUT" == *.cpio.gz && ! -e "$OUT" && ! -L "$OUT" ]] || { echo 'Invalid input or existing output' >&2; exit 2; }
for tool in python3 tar cpio gzip; do command -v "$tool" >/dev/null || exit 2; done
python3 "$ROOT/independent/validate-rootfs.py" "$ARCHIVE"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
tar --no-same-owner --no-same-permissions -xzf "$ARCHIVE" -C "$WORK"
[[ -x "$WORK/init" && -x "$WORK/bin/busybox" ]] || { echo 'Missing init or busybox' >&2; exit 2; }
mkdir -p "$(dirname "$OUT")"
(cd "$WORK" && find . -print0 | LC_ALL=C sort -z | cpio --null -o -H newc --quiet | gzip -n -9) > "$OUT"
sha256sum "$OUT" > "$OUT.sha256"
echo "Built isolated IDENT initramfs $OUT"
