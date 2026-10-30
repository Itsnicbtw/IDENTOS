#!/usr/bin/env bash
# Create a removable-media ISO file, never writes USB or internal disks.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
kernel="${1:?Usage: make-boot-iso.sh KERNEL INITRD NEW.iso}"
initrd="${2:?Usage: make-boot-iso.sh KERNEL INITRD NEW.iso}"
output="${3:?Usage: make-boot-iso.sh KERNEL INITRD NEW.iso}"
[[ "$output" == *.iso && ! -e "$output" && ! -L "$output" && "$output" != /dev/* ]] || { echo 'Refusing output path' >&2; exit 2; }
[[ -f "$kernel" && ! -L "$kernel" && -f "$initrd" && ! -L "$initrd" ]] || exit 2
for tool in grub-mkrescue xorriso sha256sum; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 2; }; done
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/boot/grub"
cp "$kernel" "$work/boot/vmlinuz"
cp "$initrd" "$work/boot/initrd.gz"
cat > "$work/boot/grub/grub.cfg" <<'EOF'
set timeout=8
set default=0
menuentry "IDENTIUM experimental rescue (RAM only)" {
 linux /boot/vmlinuz console=tty0 rdinit=/init
 initrd /boot/initrd.gz
}
EOF
grub-mkrescue -o "$output" "$work"
sha256sum "$output" > "$output.sha256"
echo 'Created experimental IDENTIUM boot ISO. Does not install to disk.'
