#!/usr/bin/env bash
# Builds the actual desktop, because a terminal with an ego isn't an OS.
# Needs Debian live-build tools. Unfortunately, hardware demands software.
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
  --archive-areas 'main non-free-firmware' --security false \
  --iso-application 'IDENT OS Live Developer Edition' \
  --iso-volume 'IDENTOS_LIVE'
mkdir -p config/package-lists config/includes.chroot/etc/identos config/includes.chroot/etc/skel
mkdir -p config/includes.chroot/usr/local/bin config/includes.chroot/usr/share/applications config/includes.chroot/etc/xdg/xfce4/xfconf/xfce-perchannel-xml config/archives
cat > config/archives/trixie-security.list.chroot <<'EOF'
deb http://security.debian.org/debian-security trixie-security main non-free-firmware
EOF

cat > config/package-lists/identos.list.chroot <<'EOF'
task-xfce-desktop
xserver-xorg-input-libinput
xserver-xorg-video-all
adwaita-icon-theme
xcursor-themes
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
pciutils
usbutils
lshw
mesa-utils
inxi
build-essential
python3
python3-venv
podman
EOF
cat > config/includes.chroot/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Adwaita"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorThemeSize" type="int" value="24"/>
  </property>
</channel>
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
cat > config/includes.chroot/usr/local/bin/identos-doctor <<'EOF'
#!/bin/sh
# Diagnoses the machine without uploading its entire life story.
set -u
printf 'IDENT OS | hardware and development diagnostics\n'
printf 'Kernel: '; uname -sr
printf 'Machine: '; uname -m
printf '\nStorage:\n'; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS 2>/dev/null || true
printf '\nGraphics:\n'; lspci 2>/dev/null | grep -Ei 'VGA|Display|3D' || true
printf '\nNetwork devices:\n'; lspci 2>/dev/null | grep -Ei 'Network|Ethernet|Wireless' || true
printf '\nMemory:\n'; free -h 2>/dev/null || true
printf '\nDevelopment tools:\n'
for bin in git gcc python3 podman; do command -v "$bin" || true; done
printf '\nThis report does not send data anywhere.\n'
EOF
chmod +x config/includes.chroot/usr/local/bin/identos-doctor
# These eggs only run when invited. Unlike mandatory corporate fun.
install -m 0755 "$ROOT/assets/identos-egg" config/includes.chroot/usr/local/bin/identos-egg
cat > config/includes.chroot/usr/share/applications/identos-egg.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=IDENT OS: Very Important Utilities
Comment=Pointless jokes, zero telemetry. The dream.
Exec=xfce4-terminal --hold --command="identos-egg all"
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF
lb build
IMAGE="$(find . -maxdepth 1 -name '*.hybrid.iso' -o -name '*.iso' | head -1)"
[[ -n "$IMAGE" && -s "$IMAGE" ]] || { echo "ERROR: live-build created no ISO" >&2; exit 1; }
cp "$IMAGE" "$OUT/identos-live-amd64.iso"
(cd "$OUT" && sha256sum identos-live-amd64.iso > identos-live-amd64.sha256)
echo "Built $OUT/identos-live-amd64.iso"
