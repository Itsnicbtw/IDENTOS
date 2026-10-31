#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
sh -n independent/boot-splash independent/init
grep -Fq 'IDENTIUM_SPLASH' independent/boot-splash
grep -Fq '/bin/boot-splash' independent/init
grep -Fq 'independent/boot-splash' independent/build-rootfs.sh
echo 'PASS: IDENTIUM boot splash installed and invoked'
