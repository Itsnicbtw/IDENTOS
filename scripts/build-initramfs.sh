#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
OUT="$ROOT/build"
BUSYBOX="${BUSYBOX:-$(command -v busybox || true)}"
[[ -n "$BUSYBOX" && -f "$BUSYBOX" ]] || { echo 'ERROR: Install busybox or set BUSYBOX=/path/to/busybox' >&2; exit 1; }
for c in cpio gzip ldd readlink find nano python3 node git gcc g++ make curl tar npm; do command -v "$c" >/dev/null || { echo "ERROR: missing $c" >&2; exit 1; }; done
case "$(uname -m)" in x86_64) ;; *) echo 'ERROR: x86-64 build host required for this milestone' >&2; exit 1;; esac
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK"/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,etc,tmp,run,data}
chmod 1777 "$WORK/tmp"
install -m 0755 rootfs/init "$WORK/init"
install -m 0755 "$BUSYBOX" "$WORK/bin/busybox"
# BusyBox applets via symlinks. All listed applets must exist in the bundled build.
for app in sh mount mknod sleep uname sync reboot poweroff ls cat echo dmesg ps mkdir grep rm cp mv pwd touch chmod head tail sed awk sort env which; do
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
done < <(ldd "$NANO" | awk '{ for (i=1;i<=NF;i++) if ($i ~ /^\//) print $i }' | sort -u)
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

# Developer edition: ship tooling rather than asking users to install it after boot.
# This increases ISO size significantly, but an empty package manager isn't useful.
for tool in git gcc g++ make curl tar; do
  executable="$(command -v "$tool")"
  install -m 0755 "$executable" "$WORK/bin/$tool"
  copy_libs "$executable"
done

# Compiler driver specs, headers, startup objects and binutils are needed
# for a real hello-world build. A gcc executable on its own compiles nothing.
for directory in /usr/lib/gcc /usr/include /usr/lib/x86_64-linux-gnu /usr/x86_64-linux-gnu /usr/lib/llvm-18; do
  if [[ -d "$directory" ]]; then
    mkdir -p "$WORK$(dirname "$directory")"
    cp -a "$directory" "$WORK$directory"
  fi
done
for tool in as ld ld.bfd collect2; do
  path="$(command -v "$tool" || true)"
  if [[ -n "$path" ]]; then
    mkdir -p "$WORK$(dirname "$path")"
    cp -L "$path" "$WORK$path"
    copy_libs "$path"
  fi
done
for path in /lib/x86_64-linux-gnu /lib64; do
  if [[ -d "$path" ]]; then
    mkdir -p "$WORK$path"
    cp -a "$path/." "$WORK$path/"
  fi
done

# Debian/Ubuntu distribute npm across /usr/share/nodejs and its entry script.
NPM="$(command -v npm)"
mkdir -p "$WORK$(dirname "$NPM")"
cp -L "$NPM" "$WORK$NPM"
if [[ -d /usr/share/nodejs ]]; then
  mkdir -p "$WORK/usr/share/nodejs"
  cp -a /usr/share/nodejs/. "$WORK/usr/share/nodejs/"
else
  echo 'ERROR: npm modules missing from build host' >&2
  exit 1
fi
if [[ -d /usr/lib/node_modules ]]; then
  mkdir -p "$WORK/usr/lib/node_modules"
  cp -a /usr/lib/node_modules/. "$WORK/usr/lib/node_modules/"
fi
# pip runs as a Python module. Debian keeps it in dist-packages.
if [[ -d /usr/lib/python3/dist-packages ]]; then
  mkdir -p "$WORK/usr/lib/python3/dist-packages"
  cp -a /usr/lib/python3/dist-packages/. "$WORK/usr/lib/python3/dist-packages/"
fi
if [[ -d /usr/local/lib/python3/dist-packages ]]; then
  mkdir -p "$WORK/usr/local/lib/python3/dist-packages"
  cp -a /usr/local/lib/python3/dist-packages/. "$WORK/usr/local/lib/python3/dist-packages/"
fi
mkdir -p "$OUT"
( cd "$WORK" && find . -print0 | LC_ALL=C sort -z | cpio --null -o --format=newc 2>/dev/null | gzip -n -9 ) > "$OUT/identos-initramfs.cpio.gz"
printf 'Created %s\n' "$OUT/identos-initramfs.cpio.gz"
