#!/usr/bin/env bash
# Create a NEW, file-backed persistence image. Never touch block devices.
set -euo pipefail
usage() { echo "Usage: $0 --output /path/new.img --size-mib 4096"; }
output= size=
while (($#)); do
 case "$1" in
 --output|--size-mib) (($#>=2)) || { usage >&2; exit 2; }; key="$1"; shift; if [[ "$key" == --output ]]; then output="$1"; else size="$1"; fi; shift;;
 --help) usage; exit 0;;
 *) usage >&2; exit 2;;
 esac
done
[[ -n "$output" && -n "$size" ]] || { usage >&2; exit 2; }
[[ "$size" =~ ^[0-9]+$ ]] && ((10#$size>=512 && 10#$size<=65536)) || { echo 'Size must be 512..65536 MiB' >&2; exit 2; }
[[ "$output" == *.img && "$output" != /dev/* && "$output" != /proc/* && "$output" != /sys/* ]] || { echo 'Only a new .img regular file is permitted' >&2; exit 2; }
[[ ! -e "$output" && ! -L "$output" ]] || { echo 'Refusing to overwrite an existing path' >&2; exit 2; }
for bin in truncate mkfs.ext4 debugfs; do command -v "$bin" >/dev/null || { echo "Missing $bin" >&2; exit 2; }; done
umask 077
trap 'rm -f -- "$output"' ERR
( set -C; : > "$output" ) || { echo 'Output already exists' >&2; exit 1; }
truncate -s "${size}M" "$output"
mkfs.ext4 -F -q -L persistence "$output"
printf '%s\n' '/ union' | debugfs -w -R 'write /dev/stdin persistence.conf' "$output" >/dev/null 2>&1 || {
  # debugfs's write requires a regular host source file on some versions.
  tmp="$(mktemp)"; trap 'rm -f "$tmp"; rm -f -- "$output"' ERR
  printf '%s\n' '/ union' > "$tmp"
  debugfs -w -R "write $tmp persistence.conf" "$output" >/dev/null
  rm -f "$tmp"
}
trap - ERR
echo "Created file-backed persistence image: $output"
echo "This is a live overlay, NOT an installed OS or encrypted storage."tmp="$(mktemp)"
trap 'rm -f "$tmp"; rm -f -- "$output"' ERR
printf '%s\n' '/ union' > "$tmp"
debugfs -w -R "write $tmp persistence.conf" "$output" >/dev/null 2>&1
rm -f "$tmp"
trap - ERR
echo "Created file-backed persistence image: $output"
echo "This is a live overlay, NOT an installed OS or encrypted storage."
