#!/usr/bin/env bash
# Build a Debian Live-based IDENT OS desktop ISO with live-build.
# Requires Debian host with live-build, debootstrap, xorriso and squashfs-tools.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
for bin in lb debootstrap mksquashfs xorriso; do
  command -v "$bin" >/dev/null || { echo "Missing $bin; install live-build debootstrap squashfs-tools xorriso" >&2; exit 1; }
done
[[ "$(id -u)" -eq 0 ]] || { echo "Run with sudo (live-build needs root)" >&2; exit 1; }
OUT="$ROOT/build"
mkdir -p "$OUT"
WORK="$(mktemp -d "$OUT/live-work.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
lb config --mode debian --distribution trixie --architectures amd64 \
  --binary-images iso-hybrid --debian-installer none \
  --bootappend-live 'boot=live components persistence quiet' \
  --archive-areas 'main non-free-firmware' \
  --iso-application 'IDENT OS Live Developer Edition' \
  --iso-volume 'IDENTOS_LIVE'
mkdir -p config/package-lists config/includes.chroot/etc/identos config/includes.chroot/etc/skel
cat > config/package-lists/identos.list.chroot <<'EOF'
task-xfce-desktop
lightdm
network-manager
network-manager-gnome
sudo
firefox-esr
thunar
xfce4-terminal
mousepad
curl
git
ca-certificates
openssh-client
EOF
cat > config/includes.chroot/etc/identos/release <<'EOF'
IDENT OS Live Developer Edition
Base: Debian GNU/Linux 13 (Trixie)
Purpose: experimental Linux desktop foundation
EOF
cat > config/includes.chroot/etc/skel/README-IDENTOS.txt <<'EOF'
Welcome to IDENT OS Live.
This is an experimental Debian/XFCE live desktop, not a secure or independent
kernel OS. Use the terminal and file manager as on a normal Debian desktop.
Persistence requires a separate partition named 'persistence' with a
persistence.conf file; see docs/live-desktop.md in the source repository.
EOF
lb build
IMAGE="$(find . -maxdepth 1 -name '*.hybrid.iso' -o -name '*.iso' | head -1)"
[[ -n "$IMAGE" && -s "$IMAGE" ]] || { echo "ERROR: live-build created no ISO" >&2; exit 1; }
cp "$IMAGE" "$OUT/identos-live-amd64.iso"
(cd "$OUT" && sha256sum identos-live-amd64.iso > identos-live-amd64.sha256)
echo "Built $OUT/identos-live-amd64.iso"
