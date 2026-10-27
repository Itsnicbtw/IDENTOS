#!/usr/bin/env bash
# Test persistence without formatting anything remotely resembling a real disk.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash scripts/create-persistence-image.sh "$tmp/persistence.img" 64
test "$(blkid -o value -s LABEL "$tmp/persistence.img")" = persistence
debugfs -R 'cat /persistence.conf' "$tmp/persistence.img" 2>/dev/null | grep -Fxq '/home union'
printf 'remember-me\n' > "$tmp/proof"
debugfs -w -R "write $tmp/proof /proof" "$tmp/persistence.img" >/dev/null 2>&1
# Re-open image independently: no magic RAM state pretending to be persistence.
debugfs -R 'cat /proof' "$tmp/persistence.img" 2>/dev/null | grep -Fxq 'remember-me'
if bash scripts/create-persistence-image.sh "$tmp/persistence.img" 64 >/dev/null 2>&1; then
  echo 'ERROR: overwrite guard failed' >&2
  exit 1
fi
echo 'PASS: safe ext4 persistence-image round trip'
