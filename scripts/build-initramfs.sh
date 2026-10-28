#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="$ROOT/build"
BUSYBOX="${BUSYBOX:-$(command -v busybox || true)}"
[[ -n "$BUSYBOX" && -f "$BUSYBOX" ]] || { echo 'ERROR: Install busybox or set BUSYBOX=/path/to/busybox' >&2; exit 1; }
for c in cpio gzip ldd readlink find nano python3 node; do command -v "$c" >/dev/null || { echo "ERROR: missing $c" >&2; exit 1; }; done
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
# Nano is an actual editor, not a pretend BusyBox alias.
# Include its shared libraries plus a real terminfo definition for the serial console.
NANO="$(command -v nano)"
install -m 0755 "$NANO" "$WORK/bin/nano"
while IFS= read -r lib; do
  [[ -f "$lib" ]] || { echo "ERROR: nano library missing: $lib" >&2; exit 1; }
  mkdir -p "$WORK$(dirname "$lib")"
  cp -L "$lib" "$WORK$lib"
done < <(ldd "$NANO" | awk '{ for (i=1;i<=NF;i++) if ($i ~ /^\\//) print $i }' | sort -u)
# Nano's curses frontend needs this, even in a QEMU serial session.
TERMINFO_FILE=""
for candidate in /lib/terminfo/v/vt100 /usr/share/terminfo/v/vt100; do
  if [[ -f "$candidate" ]]; then TERMINFO_FILE="$candidate"; break; fi
done
[[ -n "$TERMINFO_FILE" ]] || { echo 'ERROR: missing vt100/xterm terminfo definition' >&2; exit 1; }
mkdir -p "$WORK/usr/share/terminfo/v"
# Always expose the descriptor as vt100, whatever the build host provides.
cp -L "$TERMINFO_FILE" "$WORK/usr/share/terminfo/v/vt100"

# Python and Node run inside the guest, not on the host. Bundle their
# binaries AND runtime dependencies, otherwise all you built is an error message.
copy_libs() {
  local executable="$1" lib
  while IFS= read -r lib; do
    [[ -f "$lib" ]] || { echo "ERROR: dependency missing: $lib" >&2; exit 1; }
    mkdir -p "$WORK$(dirname "$lib")"
    cp -L "$lib" "$WORK$lib"
  done < <(ldd "$executable" | awk '{ for (i=1;i<=NF;i++) if ($i ~ /^\//) print $i }' | sort -u)
}
PYTHON="$(command -v python3)"
NODE="$(command -v node)"
install -m 0755 "$PYTHON" "$WORK/bin/python3"
install -m 0755 "$NODE" "$WORK/bin/node"
copy_libs "$PYTHON"
copy_libs "$NODE"

PY_STDLIB="$("$PYTHON" -c 'import sysconfig; print(sysconfig.get_path("stdlib"))')"
PY_PREFIX="$("$PYTHON" -c 'import sys; print(sys.prefix)')"
[[ -d "$PY_STDLIB" && "$PY_STDLIB" == /* && "$PY_PREFIX" == /* ]] || {
  echo 'ERROR: cannot locate Python standard library' >&2; exit 1;
}
mkdir -p "$WORK$(dirname "$PY_STDLIB")"
cp -a "$PY_STDLIB" "$WORK$PY_STDLIB"
# No reason to carry around the build machine's bytecode or test suite.
find "$WORK$PY_STDLIB" -type d \( -name __pycache__ -o -name test -o -name tests \) -prune -exec rm -rf {} +
find "$WORK$PY_STDLIB" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete

# Extension modules can have more libraries than the python executable itself.
if [[ -d "$PY_STDLIB/lib-dynload" ]]; then
  while IFS= read -r -d '' extension; do
    copy_libs "$extension"
  done < <(find "$PY_STDLIB/lib-dynload" -type f -name '*.so' -print0)
fi
cat > "$WORK/etc/identos-runtime" <<EOF
PYTHONHOME=$PY_PREFIX
EOF
mkdir -p "$OUT"
( cd "$WORK" && find . -print0 | LC_ALL=C sort -z | cpio --null -o --format=newc 2>/dev/null | gzip -n -9 ) > "$OUT/identos-initramfs.cpio.gz"
printf 'Created %s\n' "$OUT/identos-initramfs.cpio.gz"
