#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n scripts/identos-create-persistence.sh
bash scripts/identos-create-persistence.sh --help | grep -Fq -- '--size-mib'
if bash scripts/identos-create-persistence.sh --output /dev/sda --size-mib 4096 >/dev/null 2>&1; then echo 'ERROR: device path accepted' >&2; exit 1; fi
if bash scripts/identos-create-persistence.sh --output ./whatever.img --size-mib 4 >/dev/null 2>&1; then echo 'ERROR: tiny image accepted' >&2; exit 1; fi
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
touch "$tmp/existing.img"
if bash scripts/identos-create-persistence.sh --output "$tmp/existing.img" --size-mib 1024 >/dev/null 2>&1; then echo 'ERROR: existing image overwritten' >&2; exit 1; fi
echo 'PASS: persistence creator rejects unsafe options without writing storage'
