#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="$ROOT/build"
BUSYBOX="${BUSYBOX:-$(command -v busybox || true)}"
[[ -n "$BUSYBOX" && -f "$BUSYBOX" ]] || { echo 'ERROR: Install busybox or set BUSYBOX=/path/to/busybox' >&2; exit 1; }
for c in cpio gzip ldd readlink find; do command -v "$c" >/dev/null || { echo "ERROR: missing $c" >&2; exit 1; }; done
case "$(uname -m)" in x86_64) ;; *) echo 'ERROR: x86-64 build host required for this milestone' >&2; exit 1;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK"/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,etc,tmp,run,data}
chmod 1777 "$WORK/tmp"
install -m 0755 rootfs/init "$WORK/init"
install -m 0755 "$BUSYBOX" "$WORK/bin/busybox"
# BusyBox applets via symlinks. All listed applets must exist in the bundled build.
for app in sh mount mknod sleep uname sync reboot poweroff ls cat echo dmesg ps mkdir grep rm; do
  if ! "$BUSYBOX" --list | grep -Fxq "$app"; then echo "ERROR: BusyBox missing applet: $app" >&2; exit 1; fi
  ln -s busybox "$WORK/bin/$app"
done
# Bundling libraries permits distro-provided dynamically linked BusyBox.
# ldd output is used only on the trusted, locally installed BusyBox binary.
if ldd "$BUSYBOX" 2>&1 | grep -q 'not a dynamic executable'; then
  echo 'Static BusyBox detected'
else
  while IFS= read -r lib; do
    [[ -f "$lib" ]] || { echo "ERROR: library missing: $lib" >&2; exit 1; }
    mkdir -p "$WORK$(dirname "$lib")"
    cp -L "$lib" "$WORK$lib"
  done < <(ldd "$BUSYBOX" | awk '{ for (i=1;i<=NF;i++) if ($i ~ /^\//) print $i }' | sort -u)
  # Dynamic libraries can themselves be symlinks, hence cp -L.
fi
mkdir -p "$OUT"
( cd "$WORK" && find . -print0 | LC_ALL=C sort -z | cpio --null -o --format=newc 2>/dev/null | gzip -n -9 ) > "$OUT/identos-initramfs.cpio.gz"
printf 'Created %s\n' "$OUT/identos-initramfs.cpio.gz"
