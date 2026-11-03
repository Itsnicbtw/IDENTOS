#!/usr/bin/env bash
# Create a UEFI/GPT IDENTIUM virtual hard disk image. Never writes a host block device.
set -euo pipefail
usage() { echo "Usage: $0 --kernel bzImage --initrd initrd.cpio.gz --rootfs rootfs.tar.gz --output NEW.img [--size-mib 2048]"; }
kernel="" initrd="" rootfs="" output="" size=2048
while (($#)); do
  (($# >= 2)) || { usage >&2; exit 2; }
  key="$1"; value="$2"; shift 2
  case "$key" in
    --kernel) kernel="$value";; --initrd) initrd="$value";; --rootfs) rootfs="$value";;
    --output) output="$value";; --size-mib) size="$value";; *) usage >&2; exit 2;;
  esac
done
# Restrict paths because guestfish's command language is used to populate partitions.
safe_path() { [[ "$1" =~ ^[A-Za-z0-9_./-]+$ && "$1" != /dev/* && "$1" != /proc/* && "$1" != /sys/* ]]; }
for path in "$kernel" "$initrd" "$rootfs"; do
  safe_path "$path" && [[ -f "$path" && ! -L "$path" && -s "$path" ]] || { echo "Invalid input: $path" >&2; exit 2; }
done
safe_path "$output" && [[ "$output" == *.img && ! -e "$output" && ! -L "$output" ]] || { echo 'Output must be a NEW regular .img path' >&2; exit 2; }
[[ "$size" =~ ^[0-9]+$ ]] && ((10#$size >= 1024 && 10#$size <= 16384)) || { echo 'Size must be 1024..16384 MiB' >&2; exit 2; }
for command in guestfish truncate grub-mkstandalone sha256sum python3; do
  command -v "$command" >/dev/null || { echo "Missing $command" >&2; exit 2; }
done
repo="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$repo/independent/validate-rootfs.py" "$rootfs"
rootfs="$(realpath "$rootfs")"
kernel="$(realpath "$kernel")"
initrd="$(realpath "$initrd")"
umask 077
tmp="$(mktemp -d)"
created=0
cleanup() {
  status=$?
  rm -rf "$tmp"
  if ((status != 0 && created)); then rm -f -- "$output" "$output.sha256"; fi
}
trap cleanup EXIT
cat > "$tmp/grub.cfg" <<'GRUB'
set timeout=5
set default=0
menuentry 'IDENTIUM independent developer installation' {
  search --no-floppy --label IDENTROOT --set=root
  linux /boot/vmlinuz console=tty0 console=ttyS0,115200n8 rdinit=/init identium.persist=1
  initrd /boot/initrd.gz
}
GRUB
# EFI loader is unsigned. Secure Boot remains unsupported for this installer.
grub-mkstandalone -O x86_64-efi -o "$tmp/BOOTX64.EFI" \
  --modules="part_gpt fat ext2 normal linux search search_label" \
  "boot/grub/grub.cfg=$tmp/grub.cfg"
# no symlinks, existing files or physical devices accepted as output.
( set -C; : > "$output" )
created=1
truncate -s "${size}M" "$output"
# libguestfs handles the image without exposing /dev/loop* or host drives.
guestfish --rw -a "$output" <<GUESTFISH
run
part-init /dev/sda gpt
part-add /dev/sda p 2048 526335
part-add /dev/sda p 526336 -34
part-set-gpt-type /dev/sda 1 c12a7328-f81f-11d2-ba4b-00a0c93ec93b
mkfs vfat /dev/sda1
mkfs ext4 /dev/sda2
set-label /dev/sda2 IDENTROOT
mount /dev/sda2 /
tar-in $rootfs / compress:gzip
mkdir-p /boot
copy-in $kernel /boot
mv /boot/$(basename "$kernel") /boot/vmlinuz
copy-in $initrd /boot
mv /boot/$(basename "$initrd") /boot/initrd.gz
mkdir-p /boot/efi
mount /dev/sda1 /boot/efi
mkdir-p /boot/efi/EFI/BOOT
copy-in $tmp/BOOTX64.EFI /boot/efi/EFI/BOOT
umount-all
GUESTFISH
sha256sum "$output" > "$output.sha256"
echo "Created experimental UEFI GPT virtual disk image: $output"
echo 'WARNING: contains unauthenticated emergency root shell. VM-only; no physical installation.'
