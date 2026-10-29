#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n scripts/identos-readiness.sh scripts/identos-system-report.sh
bash scripts/identos-readiness.sh --help | grep -Fq 'without modifying disks'
bash scripts/identos-readiness.sh --host
if bash scripts/identos-readiness.sh --unknown >/dev/null 2>&1; then
  echo 'invalid readiness arguments were accepted' >&2; exit 1
fi
if grep -Eq '(^|[[:space:]])(mkfs|parted|wipefs|dd[[:space:]])' scripts/identos-readiness.sh scripts/identos-system-report.sh; then
  echo 'read-only diagnostic contains disk mutation command' >&2; exit 1
fi
echo 'PASS: release-readiness diagnostics are syntax-valid and non-destructive'
