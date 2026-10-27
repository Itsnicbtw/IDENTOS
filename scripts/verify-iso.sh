#!/usr/bin/env bash
# Validate the generated ISO, its boot assets, and create a distributable SHA256 manifest.
set -euo pipefail
cd "$(dirname "$0")/.."
ISO=build/identos-dev-x86_64.iso
[[ -s "$ISO" ]] || { echo "ERROR: missing ISO: $ISO" >&2; exit 1; }
for cmd in xorriso sha256sum; do command -v "$cmd" >/dev/null || { echo "ERROR: missing $cmd" >&2; exit 1; }; done
for asset in /boot/grub/grub.cfg /boot/vmlinuz /boot/initramfs.gz; do
  if ! xorriso -osirrox on -indev "$ISO" -extract "$asset" /dev/null >/dev/null 2>&1; then
    echo "ERROR: ISO missing $asset" >&2
    exit 1
  fi
done
(
  cd build
  sha256sum identos-dev-x86_64.iso > SHA256SUMS
  sha256sum -c SHA256SUMS
)
echo 'PASS: ISO boot assets and SHA256 integrity manifest'
