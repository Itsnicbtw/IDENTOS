#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n independent/build-rootfs.sh independent/build-initrd.sh independent/boot-qemu.sh independent/build-vm-disk.sh
sh -n independent/init
python3 -m py_compile independent/validate-rootfs.py independent/slot-manager.py independent/repository.py
# Boot path never passes a physical disk into QEMU.
if grep -Eq -- '-(drive|hda|hdb|device[[:space:]]+.*blockdev)' independent/boot-qemu.sh; then
 echo 'Unexpected disk device in isolated QEMU boot' >&2; exit 1
fi
echo 'PASS: isolated boot scripts parse and do not attach drives'
