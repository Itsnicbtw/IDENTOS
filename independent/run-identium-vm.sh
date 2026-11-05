#!/usr/bin/env bash
# Launch an IDENTIUM developer VM without modifying host drives or firmware.
set -euo pipefail
usage(){ echo "Usage: $0 --disk PATH.img [--memory 2048] | --iso PATH.iso [--memory 2048]"; }
disk="" iso="" memory=2048
while (($#)); do
  (($#>=2)) || { usage >&2; exit 2; }
  case "$1" in
    --disk) disk="$2";;
    --iso) iso="$2";;
    --memory) memory="$2";;
    *) usage >&2; exit 2;;
  esac
  shift 2
done
[[ -z "$disk" || -z "$iso" ]] || { usage >&2; exit 2; }
[[ -n "$disk" || -n "$iso" ]] || { usage >&2; exit 2; }
[[ "$memory" =~ ^[0-9]+$ ]] && ((10#$memory>=512 && 10#$memory<=8192)) || { echo 'Memory must be 512..8192 MiB' >&2; exit 2; }
command -v qemu-system-x86_64 >/dev/null || { echo 'Missing qemu-system-x86_64' >&2; exit 2; }
firmware=""
for candidate in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/ovmf/OVMF_CODE.fd; do
  if [[ -f "$candidate" ]]; then firmware="$candidate"; break; fi
done
[[ -n "$firmware" ]] || { echo 'OVMF UEFI firmware not found. Install ovmf.' >&2; exit 2; }
args=(-machine q35 -m "$memory" -smp 2 -bios "$firmware" -nic none)
if [[ -n "$disk" ]]; then
  [[ "$disk" == *.img && -f "$disk" && ! -L "$disk" && "$disk" != /dev/* ]] || { echo 'Disk must be an existing .img file' >&2; exit 2; }
  args+=(-drive "file=$disk,if=virtio,format=raw")
else
  [[ "$iso" == *.iso && -f "$iso" && ! -L "$iso" ]] || { echo 'ISO must be an existing .iso file' >&2; exit 2; }
  args+=(-cdrom "$iso" -boot d)
fi
echo 'Launching isolated IDENTIUM VM (no network, no physical disks).'
exec qemu-system-x86_64 "${args[@]}"
