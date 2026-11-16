#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n independent/run-identium-vm.sh
if bash independent/run-identium-vm.sh --disk /dev/sda >/dev/null 2>&1; then
  echo 'FAIL: raw physical device accepted' >&2; exit 1
fi
if bash independent/run-identium-vm.sh --disk /tmp/nonexistent-identium.img >/dev/null 2>&1; then
  echo 'FAIL: nonexistent image accepted' >&2; exit 1
fi
echo 'PASS: IDENTIUM VM launch option validation'
