#!/usr/bin/env bash
# Integration check: install rootfs into a regular ext4 file; save and read data.
set -euo pipefail
cd "$(dirname "$0")/.."
for tool in mkfs.ext4 debugfs e2fsck truncate; do command -v "$tool" >/dev/null || exit 2; done
[[ -f build/identos-independent-rootfs.tar.gz ]] || { echo 'Build rootfs first' >&2; exit 2; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
bash independent/build-vm-disk.sh --rootfs build/identos-independent-rootfs.tar.gz --output "$work/root.img" --size-mib 512
test "$(blkid -p -s LABEL -o value "$work/root.img")" = IDENTROOT
printf '%s\n' 'IDENTIUM persistence regression' >"$work/note.txt"
debugfs -w -R "mkdir /persist" "$work/root.img" >/dev/null 2>&1
debugfs -w -R "write $work/note.txt /persist/note.txt" "$work/root.img" >/dev/null 2>&1
debugfs -R "cat /persist/note.txt" "$work/root.img" >"$work/readback.txt" 2>/dev/null
grep -Fq 'IDENTIUM persistence regression' "$work/readback.txt"
e2fsck -fn "$work/root.img" >/dev/null
echo 'PASS: file-backed IDENTROOT accepts and retains data; not a real reboot test'
