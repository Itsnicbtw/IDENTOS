#!/usr/bin/env bash
# IDENTIUM Secure Boot signing preparation. NEVER creates/enrols keys in firmware.
set -euo pipefail
usage() { echo "Usage: $0 verify --image EFI --certificate CERT.pem | sign --image EFI --key KEY.pem --certificate CERT.pem --output NEW.efi"; }
(($#)) || { usage >&2; exit 2; }
action="$1"; shift
image="" key="" cert="" output=""
while (($#)); do
 case "$1" in
 --image|--key|--certificate|--output) (($#>=2)) || exit 2; flag="$1"; shift; case "$flag" in --image) image="$1";; --key) key="$1";; --certificate) cert="$1";; --output) output="$1";; esac; shift;;
 --help) usage; exit 0;;
 *) usage >&2; exit 2;;
 esac
done
command -v sbsign >/dev/null || { echo 'Install sbsigntool' >&2; exit 2; }
command -v sbverify >/dev/null || { echo 'Install sbsigntool' >&2; exit 2; }
[[ -f "$image" && ! -L "$image" && -f "$cert" && ! -L "$cert" ]] || { echo 'Image and certificate must be ordinary files' >&2; exit 2; }
case "$action" in
 verify)
  [[ -z "$key" && -z "$output" ]] || exit 2
  exec sbverify --cert "$cert" "$image";;
 sign)
  [[ -n "$output" && "$output" == *.efi && ! -e "$output" && ! -L "$output" && -f "$key" && ! -L "$key" ]] || { echo 'Use a new .efi output and an explicit key' >&2; exit 2; }
  [[ "$(stat -c %a "$key")" == 600 || "$(stat -c %a "$key")" == 400 ]] || { echo 'Private key must have permission mode 0600 or 0400' >&2; exit 2; }
  trap 'rm -f -- "$output"' ERR
  sbsign --key "$key" --cert "$cert" --output "$output" "$image"
  sbverify --cert "$cert" "$output"
  trap - ERR
  echo "Signed and verified $output. Firmware trust/enrolment NOT configured.";;
 *) usage >&2; exit 2;;
esac
