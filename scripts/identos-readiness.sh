#!/usr/bin/env bash
# Deterministic, non-destructive preflight for the experimental IDENT OS desktop.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mode="${1:---host}"
case "$mode" in --host|--image|--help) ;; *) echo "Usage: $0 [--host|--image|--help]" >&2; exit 2;; esac
if [[ "$mode" == --help ]]; then
  echo "Check IDENT OS alpha readiness without modifying disks or configuration."
  exit 0
fi
failed=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failed=$((failed+1)); }
check_file() { if [[ -s "$ROOT/$1" ]]; then pass "$1 present"; else fail "$1 missing"; fi; }
check_file desktop/identos-session
check_file desktop/identos-panel.py
check_file scripts/build-live-iso.sh
check_file scripts/smoke-graphics-qemu.sh
check_file LICENSE
if bash -n "$ROOT/scripts/build-live-iso.sh" "$ROOT/scripts/boot-live-vm.sh" "$ROOT/scripts/smoke-graphics-qemu.sh"; then
  pass 'critical shell scripts parse'
else
  fail 'critical shell scripts failed syntax check'
fi
if command -v python3 >/dev/null 2>&1 && python3 - <<'PY'
import ast
from pathlib import Path
ast.parse(Path("desktop/identos-panel.py").read_text())
PY
then pass 'desktop panel Python syntax'
else fail 'desktop panel Python syntax or Python missing'
fi
if [[ "$mode" == --image ]]; then
  iso="$ROOT/build/identos-live-amd64.iso"
  if [[ -s "$iso" ]]; then
    pass 'graphical ISO exists'
    if [[ -f "$ROOT/build/identos-live-amd64.sha256" ]] && (cd "$ROOT/build" && sha256sum -c identos-live-amd64.sha256 >/dev/null); then
      pass 'ISO checksum validated'
    else fail 'ISO checksum unavailable or invalid'; fi
  else fail 'graphical ISO not built'; fi
fi
printf '\nFailed checks: %d\n' "$failed"
if ((failed)); then exit 1; fi
echo 'PASS: source/image preflight. Interactive desktop, installation and real-hardware testing remain separate gates.'
