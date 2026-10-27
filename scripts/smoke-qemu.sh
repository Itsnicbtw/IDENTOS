#!/usr/bin/env bash
# QEMU serial-console boot smoke test. Requires KERNEL=<x86_64 bzImage>.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -s build/identos-initramfs.cpio.gz ]]; then ./scripts/build-initramfs.sh; fi
KERNEL="${KERNEL:-}"
if [[ -z "$KERNEL" ]]; then
  for candidate in /boot/vmlinuz-*; do
    [[ -f "$candidate" ]] && { KERNEL="$candidate"; break; }
  done
fi
[[ -n "$KERNEL" && -f "$KERNEL" ]] || { echo 'ERROR: provide KERNEL=/path/to/vmlinuz' >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || { echo 'ERROR: QEMU is not installed' >&2; exit 1; }
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
# timeout exits 124 on a still-running guest, expected for the interactive shell.
set +e
timeout 45s env KERNEL="$KERNEL" ./scripts/run-qemu.sh </dev/null >"$LOG" 2>&1
status=$?
set -e
if grep -Fq 'IDENT OS | Alpha 0.0.1 | Linux boot prototype' "$LOG" && grep -Fq 'identos#' "$LOG"; then
  echo 'PASS: IDENT OS booted and reached command prompt in QEMU'
else
  cat "$LOG" >&2
  echo "FAIL: IDENT OS boot did not reach prompt (exit $status)" >&2
  exit 1
fi
