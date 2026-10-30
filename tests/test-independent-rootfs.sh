#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n independent/build-rootfs.sh
sh -n independent/init
grep -Fq 'Refusing to overwrite output' independent/build-rootfs.sh
grep -Fq 'BUSYBOX_SHA256' independent/build-rootfs.sh
grep -Fq 'readelf -l' independent/build-rootfs.sh
if BUSYBOX_STATIC=/dev/null BUSYBOX_SHA256=abc bash independent/build-rootfs.sh /tmp/not-a-device.tar.gz >/dev/null 2>&1; then
 echo 'ERROR: invalid input accepted' >&2; exit 1
fi
echo 'PASS: independent rootfs static safeguards; full build awaits audited static BusyBox'
