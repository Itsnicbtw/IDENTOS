#!/usr/bin/env bash
# Construct a minimal IDENT-managed rootfs from a pinned external STATIC BusyBox.
# This does not fetch or trust random binaries and never writes physical disks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/build/identos-independent-rootfs.tar.gz}"
BUSYBOX_STATIC="${BUSYBOX_STATIC:-}"
[[ -n "$BUSYBOX_STATIC" && -f "$BUSYBOX_STATIC" && ! -L "$BUSYBOX_STATIC" ]] || {
 echo 'Set BUSYBOX_STATIC to an audited statically linked BusyBox binary' >&2; exit 2;
}
[[ -n "${BUSYBOX_SHA256:-}" && "$BUSYBOX_SHA256" =~ ^[a-fA-F0-9]{64}$ ]] || {
 echo 'BUSYBOX_SHA256 must be the expected SHA-256 of the binary' >&2; exit 2;
}
printf '%s  %s\n' "$BUSYBOX_SHA256" "$BUSYBOX_STATIC" | sha256sum -c - >/dev/null
if readelf -l "$BUSYBOX_STATIC" | grep -q 'INTERP'; then
 echo 'Dynamic ELF interpreter detected; static BusyBox required' >&2; exit 2
fi
[[ "$OUT" == *.tar.gz && "$OUT" != /dev/* ]] || { echo 'Output must be a .tar.gz file' >&2; exit 2; }
mkdir -p "$(dirname "$OUT")"
[[ ! -e "$OUT" && ! -L "$OUT" ]] || { echo 'Refusing to overwrite output' >&2; exit 2; }
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK"/{bin,sbin,usr/bin,etc,proc,sys,dev,run,tmp,root,var,home,mnt}
chmod 1777 "$WORK/tmp"
chmod 0700 "$WORK/root"
install -m 0755 "$BUSYBOX_STATIC" "$WORK/bin/busybox"
for app in sh mount sleep ls cat echo mkdir uname dmesg ps reboot poweroff sync; do
 "$BUSYBOX_STATIC" --list | grep -Fxq "$app" || { echo "Missing applet $app" >&2; exit 2; }
 ln -s busybox "$WORK/bin/$app"
done
install -m 0755 "$ROOT/independent/init" "$WORK/init"
printf 'NAME="IDENT OS Independent Minimal"\nID=identos\nVERSION_ID="0.1-dev"\nPRETTY_NAME="IDENT OS Independent Minimal (experimental)"\n' >"$WORK/etc/os-release"
printf 'root:x:0:0:root:/root:/bin/sh\n' >"$WORK/etc/passwd"
printf 'root:x:0:\n' >"$WORK/etc/group"
# The emergency root console is intentionally insecure: VM-only research.
TZ=UTC tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner -czf "$OUT" -C "$WORK" .
sha256sum "$OUT" >"$OUT.sha256"
printf 'Created experimental independent rootfs: %s\n' "$OUT"
