#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
sh -n independent/boot-splash independent/init
grep -Fq 'IDENTIUM_SPLASH' independent/boot-splash
grep -Fq 'IDENTIUM_DRAW_ATTEMPTS' independent/boot-splash
grep -Fq 'draw_ident' independent/boot-splash
grep -Fq 'stroke 8 8' independent/boot-splash
if grep -Fq 'Starting %s' independent/boot-splash; then echo 'Old progress-bar animation found' >&2; exit 1; fi
grep -Fq '/bin/boot-splash' independent/init
grep -Fq 'independent/boot-splash' independent/build-rootfs.sh
echo 'PASS: IDENTIUM boot splash installed and invoked'
