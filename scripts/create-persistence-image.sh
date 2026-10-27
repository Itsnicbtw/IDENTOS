#!/usr/bin/env bash
# Build a persistence image. Your actual SSD is not our test subject.
set -euo pipefail
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 OUTPUT.img SIZE_MIB (minimum 64)" >&2
  exit 2
fi
output="$1"
size="$2"
[[ "$size" =~ ^[0-9]+$ ]] && ((size >= 64 && size <= 16384)) || { echo "Size must be 64..16384 MiB" >&2; exit 2; }
[[ "$output" == *.img ]] || { echo "Only .img output is accepted" >&2; exit 2; }
[[ ! -e "$output" && ! -L "$output" ]] || { echo "Refusing to overwrite: $output" >&2; exit 1; }
[[ ! "$output" =~ ^/dev/ ]] || { echo "No device writes allowed" >&2; exit 1; }
command -v mkfs.ext4 >/dev/null || { echo "Install e2fsprogs" >&2; exit 1; }
mkdir -p "$(dirname "$output")"
truncate -s "${size}M" "$output"
if ! mkfs.ext4 -F -q -L persistence "$output"; then rm -f "$output"; exit 1; fi
cfg="$(mktemp)"
trap 'rm -f "$cfg"' EXIT
printf '/home union\n' > "$cfg"
debugfs -w -R "write $cfg /persistence.conf" "$output" >/dev/null
echo "Created: $output"
echo "Attach as a separate virtual disk when booting with persistence enabled."
