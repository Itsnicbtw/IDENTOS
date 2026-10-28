#!/usr/bin/env bash
# Build the little bootable monster.
set -euo pipefail

cd "$(dirname "$0")/.."

KERNEL="${KERNEL:-}"
if [[ -z "$KERNEL" ]]; then
  # First local kernel will do. We aren't building the kernel here.
  for candidate in /boot/vmlinuz-*; do
    if [[ -f "$candidate" ]]; then
      KERNEL="$candidate"
      break
    fi
  done
fi

if [[ -z "$KERNEL" || ! -f "$KERNEL" ]]; then
  echo 'ERROR: KERNEL=/path/to/vmlinuz is required' >&2
  exit 1
fi

for cmd in grub-mkrescue xorriso; do
  if ! command -v "$cmd" >/dev/null; then
    echo "ERROR: install $cmd" >&2
    exit 1
  fi
done

./scripts/build-initramfs.sh
mkdir -p build

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/boot/grub"
cp "$KERNEL" "$STAGE/boot/vmlinuz"
cp build/identos-initramfs.cpio.gz "$STAGE/boot/initramfs.gz"

# Serial console stays on. Easier to see what exploded in QEMU.
cat > "$STAGE/boot/grub/grub.cfg" <<'EOF'
set timeout=2
set default=0
serial --unit=0 --speed=115200
terminal_input console serial
terminal_output console serial
menuentry "IDENT OS - developer boot" {
  linux /boot/vmlinuz console=ttyS0 rdinit=/init panic=1
  initrd /boot/initramfs.gz
}
EOF

grub-mkrescue -o build/identos-dev-x86_64.iso "$STAGE" >/dev/null 2>&1
test -s build/identos-dev-x86_64.iso
echo "Built build/identos-dev-x86_64.iso"
