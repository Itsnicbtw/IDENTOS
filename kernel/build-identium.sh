#!/usr/bin/env bash
# Compile a branded, configured upstream Linux kernel, without host installation.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${IDENTIUM_KERNEL_SOURCE:-}"
OUTPUT="${IDENTIUM_KERNEL_OUTPUT:-$ROOT/build/identium-kernel}"
JOBS="${IDENTIUM_KERNEL_JOBS:-2}"
[[ -n "$SOURCE" && -f "$SOURCE/Makefile" && -f "$SOURCE/scripts/kconfig/merge_config.sh" ]] || {
  echo 'Set IDENTIUM_KERNEL_SOURCE to an extracted, trusted Linux kernel source tree' >&2; exit 2;
}
[[ "$JOBS" =~ ^[0-9]+$ ]] && ((JOBS>=1 && JOBS<=32)) || { echo 'Invalid job count' >&2; exit 2; }
[[ ! -L "$OUTPUT" && "$OUTPUT" != /dev/* && "$OUTPUT" != /sys/* && "$OUTPUT" != /proc/* ]] || exit 2
for tool in make cc bc bison flex openssl; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 2; }; done
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
SOURCE="$(cd "$SOURCE" && pwd)"
[[ "$OUTPUT" != "$SOURCE" && "$OUTPUT" != "$SOURCE/"* ]] || { echo 'Build outside the source tree' >&2; exit 2; }
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 x86_64_defconfig
# Merge the IDENTIUM policy on top of the upstream baseline.
KCONFIG_CONFIG="$OUTPUT/.config" "$SOURCE/scripts/kconfig/merge_config.sh" -m -O "$OUTPUT" "$OUTPUT/.config" "$ROOT/kernel/config/identium-x86_64.fragment"
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 olddefconfig
make -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 -j"$JOBS" bzImage
test -s "$OUTPUT/arch/x86/boot/bzImage"
sha256sum "$OUTPUT/arch/x86/boot/bzImage" > "$OUTPUT/bzImage.sha256"
make -s -C "$SOURCE" O="$OUTPUT" ARCH=x86_64 kernelrelease > "$OUTPUT/identium-kernel-release.txt"
echo "Built IDENTIUM Linux kernel: $(cat "$OUTPUT/identium-kernel-release.txt")"
echo 'No host kernel, bootloader, firmware, or partitions were modified.'
