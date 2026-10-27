#!/usr/bin/env bash
# Boot the desktop in a VM. No physical disks will be volunteered as tribute.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO="$ROOT/build/identos-live-amd64.iso"
FIRMWARE=bios
PERSIST=
RAM=4096
CPUS=2
usage() {
  cat <<'HELP'
Usage: scripts/boot-live-vm.sh [--iso PATH] [--ram MIB] [--cpus N]
                               [--persist PATH.img] [--uefi] [--help]

Boot IDENT OS's graphical live ISO in a QEMU window.
--persist attaches an EXISTING, regular .img file as a writable virtio disk.
No host block devices are accepted. Run create-persistence-image.sh first.
--uefi requires installed OVMF firmware. BIOS is the default.
HELP
}
die() { echo "ERROR: $*" >&2; exit 2; }
while (($#)); do
  case "$1" in
    --iso|--ram|--cpus|--persist)
      (($# >= 2)) || die "Missing argument for $1"
      case "$1" in
        --iso) ISO="$2";;
        --ram) RAM="$2";;
        --cpus) CPUS="$2";;
        --persist) PERSIST="$2";;
      esac
      shift 2;;
    --uefi) FIRMWARE=uefi; shift;;
    --help|-h) usage; exit 0;;
    *) die "Unknown option $1";;
  esac
done
command -v qemu-system-x86_64 >/dev/null || die "Install qemu-system-x86"
[[ -f "$ISO" && ! -L "$ISO" && -s "$ISO" ]] || die "Missing ISO: $ISO"
[[ "$RAM" =~ ^[0-9]+$ ]] && ((RAM >= 2048 && RAM <= 65536)) || die "RAM must be 2048..65536 MiB"
[[ "$CPUS" =~ ^[0-9]+$ ]] && ((CPUS >= 1 && CPUS <= 32)) || die "CPUs must be 1..32"
if [[ -n "$PERSIST" ]]; then
  [[ "$PERSIST" == *.img && -f "$PERSIST" && ! -L "$PERSIST" ]] || die "Persistence must be an existing regular .img file"
  [[ "$(readlink -f "$PERSIST")" != /dev/* ]] || die "Physical devices aren't supported"
  [[ ! "$PERSIST" -ef "$ISO" ]] || die "ISO and persistence file must differ"
  if command -v blkid >/dev/null; then
    label="$(blkid -p -s LABEL -o value "$PERSIST" 2>/dev/null || true)"
    [[ "$label" == persistence ]] || die "Persistence image must contain an ext4 filesystem labelled persistence"
  fi
fi
# Check published checksum when booting the standard output file.
if [[ "$ISO" -ef "$ROOT/build/identos-live-amd64.iso" && -f "$ROOT/build/identos-live-amd64.sha256" ]]; then
  (cd "$ROOT/build" && sha256sum -c identos-live-amd64.sha256) || die "ISO checksum mismatch"
fi
args=(-machine q35 -m "$RAM" -smp "$CPUS" -boot d -cdrom "$ISO" -display gtk
      -device virtio-vga -device usb-tablet -nic user,model=virtio-net-pci)
if [[ -n "$PERSIST" ]]; then
  args+=(-drive "file=$PERSIST,format=raw,if=virtio,cache=none")
fi
if [[ "$FIRMWARE" == uefi ]]; then
  ovmf=
  for candidate in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd; do
    if [[ -f "$candidate" ]]; then ovmf="$candidate"; break; fi
  done
  [[ -n "$ovmf" ]] || die "OVMF firmware missing: install ovmf, or omit --uefi"
  args+=(-drive "if=pflash,format=raw,readonly=on,file=$ovmf")
fi
echo "Starting IDENT OS graphical VM ($FIRMWARE, ${RAM} MiB RAM, $CPUS CPUs)."
echo "Close the QEMU window to stop. The ISO is read-only."
exec qemu-system-x86_64 "${args[@]}"
