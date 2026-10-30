#!/usr/bin/env bash
# Build an ext4 filesystem in a NEW regular file, never on a block device.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
usage() { echo "Usage: $0 --rootfs ROOTFS.tar.gz --output NEW.img --size-mib 2048"; }
archive="" output="" size=2048
while (($#)); do
 case "$1" in
 --rootfs|--output|--size-mib)
   (($#>=2)) || { usage >&2; exit 2; }
   key="$1"; shift
   case "$key" in --rootfs) archive="$1";; --output) output="$1";; --size-mib) size="$1";; esac; shift;;
 --help) usage; exit 0;;
 *) usage >&2; exit 2;;
 esac
done
[[ -f "$archive" && ! -L "$archive" && "$output" == *.img && "$output" != /dev/* && "$output" != /sys/* && "$output" != /proc/* ]] || { usage >&2; exit 2; }
[[ "$size" =~ ^[0-9]+$ ]] && ((10#$size>=512 && 10#$size<=16384)) || { echo 'Size must be 512..16384 MiB' >&2; exit 2; }
[[ ! -e "$output" && ! -L "$output" ]] || { echo 'Refusing existing output' >&2; exit 2; }
for bin in truncate mkfs.ext4 tar debugfs sha256sum; do command -v "$bin" >/dev/null || exit 2; done
# Archive must contain only safe relative paths. Reject links until a verified extractor exists.
python3 "$ROOT/independent/validate-rootfs.py" "$archive"
umask 077
created=0
cleanup() { status=$?; if ((status!=0 && created==1)); then rm -f -- "$output"; fi; }
trap cleanup EXIT
( set -C; : > "$output" )
created=1
truncate -s "${size}M" "$output"
mkfs.ext4 -q -F -L IDENTROOT -d /dev/null "$output" 2>/dev/null || mkfs.ext4 -q -F -L IDENTROOT "$output"
# Stage validated archive in a private temp directory for mkfs -d.
stage="$(mktemp -d)"
trap 'status=$?; rm -rf "$stage"; if ((status!=0 && created==1)); then rm -f -- "$output"; fi' EXIT
tar -xzf "$archive" -C "$stage" --no-same-owner --no-same-permissions
mkfs.ext4 -q -F -L IDENTROOT -d "$stage" "$output"
sha256sum "$output" >"$output.sha256"
echo "Created isolated root filesystem image: $output"
echo 'Not bootable alone: a kernel and bootloader are still required.'
