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
  --bootappend-live 'boot=live components persistence console=tty0 console=ttyS0,115200n8' \
  --archive-areas 'main non-free-firmware' --security false \
  --iso-application 'IDENT OS Live Developer Edition' \
  --iso-volume 'IDENTOS_LIVE'
mkdir -p config/package-lists config/includes.chroot/etc/identos config/includes.chroot/etc/skel
mkdir -p config/includes.chroot/usr/local/bin config/includes.chroot/usr/share/applications config/archives
# Base runtime is explicit and checked at boot, not inferred from desktop packages.
mkdir -p config/includes.chroot/etc/systemd/system/multi-user.target.wants
mkdir -p config/includes.chroot/etc/tmpfiles.d config/includes.chroot/etc/sysctl.d
mkdir -p config/includes.chroot/usr/lib/systemd/system
install -m 0755 "$ROOT/base-os/identos-base-check" config/includes.chroot/usr/local/bin/identos-base-check
install -m 0644 "$ROOT/base-os/identos-base-check.service" config/includes.chroot/usr/lib/systemd/system/identos-base-check.service
ln -s /usr/lib/systemd/system/identos-base-check.service config/includes.chroot/etc/systemd/system/multi-user.target.wants/identos-base-check.service
install -m 0644 "$ROOT/base-os/identos-base.tmpfiles" config/includes.chroot/etc/tmpfiles.d/identos-base.conf
install -m 0644 "$ROOT/base-os/identos-base.sysctl" config/includes.chroot/etc/sysctl.d/60-identos-base.conf
cat > config/archives/trixie-security.list.chroot <<'EOF'
deb http://security.debian.org/debian-security trixie-security main non-free-firmware
EOF

cat > config/package-lists/identos.list.chroot <<'EOF'
openbox
xorg
systemd-sysv
udev
dbus
polkitd
pkexec
initramfs-tools
linux-image-amd64
locales
tzdata
passwd
xserver-xorg-core
python3-tk
libgtk-3-dev
pkg-config
x11-xserver-utils
xterm
pcmanfm
rofi
feh
imagemagick
xserver-xorg-input-libinput
xserver-xorg-video-all
adwaita-icon-theme
xcursor-themes
lightdm
network-manager
network-manager-gnome
sudo
firefox-esr
zenity
xdg-utils
mousepad
curl
git
ca-certificates
openssh-client
pciutils
usbutils
lshw
mesa-utils
mesa-vulkan-drivers
inxi
build-essential
python3
python3-venv
python3-pip
nodejs
npm
nano
vim
podman
EOF
cat > config/includes.chroot/etc/identos/theme.xml <<'EOF'
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
This is an experimental Debian/IDENT live desktop, not a secure or independent
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
Exec=xterm -hold -e identos-egg all
Icon=utilities-terminal
Terminal=false
Categories=Utility;
EOF

# Usable graphical defaults, with browser selection that never claims missing
# proprietary or privacy-sensitive browsers are magically installed.
mkdir -p config/includes.chroot/etc/skel/Desktop
mkdir -p config/includes.chroot/etc/lightdm/lightdm.conf.d

cat > config/includes.chroot/etc/lightdm/lightdm.conf.d/60-identos.conf <<'EOF'
[Seat:*]
user-session=identos
greeter-hide-users=false
EOF

cat > config/includes.chroot/usr/local/bin/identos-browser <<'EOF'
#!/bin/sh
# Selection is separate from installation: don't silently fetch executables.
set -eu
choice="$(zenity --list --title='IDENT OS | Browser' --text='Choose a browser' \
  --column='Browser' 'Firefox' 'Google Chrome' 'Tor Browser' 'Aster' \
  --height=300 --width=420 2>/dev/null)" || exit 0
case "$choice" in
  Firefox)
    command -v firefox-esr >/dev/null 2>&1 && exec firefox-esr
    ;;
  'Google Chrome')
    for cmd in google-chrome-stable google-chrome; do
      command -v "$cmd" >/dev/null 2>&1 && exec "$cmd"
    done
    ;;
  'Tor Browser')
    command -v torbrowser-launcher >/dev/null 2>&1 && exec torbrowser-launcher
    ;;
  Aster)
    command -v aster >/dev/null 2>&1 && exec aster
    ;;
  *) exit 0 ;;
esac
zenity --warning --title='Browser unavailable' \
  --text="$choice is not included in this build. Firefox ESR is preinstalled." 2>/dev/null || true
EOF
chmod +x config/includes.chroot/usr/local/bin/identos-browser
cat > config/includes.chroot/usr/share/applications/identos-browser.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=IDENT OS Browser Selection
Comment=Choose an available browser
Exec=identos-browser
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
EOF
cat > config/includes.chroot/etc/skel/Desktop/identos-browser.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Choose Browser
Exec=identos-browser
Icon=web-browser
Terminal=false
Categories=Network;
EOF
chmod +x config/includes.chroot/etc/skel/Desktop/identos-browser.desktop

cat > config/includes.chroot/etc/skel/Desktop/identos-terminal.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Exec=xterm
Icon=utilities-terminal
Terminal=false
Categories=System;
EOF
chmod +x config/includes.chroot/etc/skel/Desktop/identos-terminal.desktop

# Default desktop artwork and useful diagnostics for the graphical edition.
mkdir -p config/includes.chroot/usr/share/backgrounds/identos
cat > config/includes.chroot/usr/share/backgrounds/identos/identos.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
<defs><linearGradient id="b" x2="1" y2="1"><stop stop-color="#101523"/><stop offset="1" stop-color="#26395b"/></linearGradient></defs>
<rect width="1920" height="1080" fill="url(#b)"/>
<circle cx="1510" cy="470" r="390" fill="#5474aa" opacity=".10"/>
<text x="100" y="920" fill="#e7edf8" font-family="sans-serif" font-size="70" font-weight="700">IDENT OS</text>
<text x="104" y="970" fill="#a9bbd7" font-family="sans-serif" font-size="26">Developer Live Edition</text>
</svg>
EOF
cat > config/includes.chroot/usr/local/bin/identos-graphics-check <<'EOF'
#!/bin/sh
set -u
echo "IDENT OS graphics check"
printf 'Session: %s\n' "$XDG_CURRENT_DESKTOP"
printf 'Display: %s\n' "$DISPLAY"
command -v Xorg || true
command -v openbox || true
command -v firefox-esr || true
command -v glxinfo >/dev/null 2>&1 && glxinfo -B 2>/dev/null || true
echo "Graphics diagnostics complete."
EOF
chmod +x config/includes.chroot/usr/local/bin/identos-graphics-check
cat > config/includes.chroot/usr/share/applications/identos-graphics-check.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=IDENT OS Graphics Diagnostics
Exec=xterm -hold -e identos-graphics-check
Icon=video-display
Terminal=false
Categories=System;
EOF

# This is the real desktop session, not an XFCE panel with a new wallpaper.
mkdir -p config/includes.chroot/usr/share/xsessions
install -m 0755 "$ROOT/desktop/identos-panel.py" config/includes.chroot/usr/local/bin/identos-panel
mkdir -p config/includes.chroot/usr/local/share/identos
cp "$ROOT/desktop/identos2/panel.c" config/includes.chroot/usr/local/share/identos/panel.c
install -m 0755 "$ROOT/desktop/identos-session" config/includes.chroot/usr/local/bin/identos-session
install -m 0755 "$ROOT/desktop/identos-benchmark.sh" config/includes.chroot/usr/local/bin/identos-benchmark
install -m 0755 "$ROOT/system/identos-capabilities.py" config/includes.chroot/usr/local/bin/identos-capabilities
install -m 0755 "$ROOT/scripts/identos-system-report.sh" config/includes.chroot/usr/local/bin/identos-system-report
install -m 0755 "$ROOT/scripts/identos-update-check.sh" config/includes.chroot/usr/local/bin/identos-update-check
cat > config/hooks/normal/0790-identos-desktop2.hook.chroot <<'EOF'
#!/bin/sh
set -eu
cc -O2 -std=c11 -Wall -Wextra -Wno-deprecated-declarations $(pkg-config --cflags gtk+-3.0) /usr/local/share/identos/panel.c -o /usr/local/bin/identos-panel2 $(pkg-config --libs gtk+-3.0)
chmod 0755 /usr/local/bin/identos-panel2
rm -f /usr/local/share/identos/panel.c
EOF
chmod +x config/hooks/normal/0790-identos-desktop2.hook.chroot
cat > config/includes.chroot/usr/local/bin/identos-session2 <<'EOF'
#!/bin/sh
# IDENT Desktop 2 experimental session; preserve Desktop 1 as fallback.
set -eu
export XDG_CURRENT_DESKTOP=IDENT
export XDG_SESSION_DESKTOP=identos2
openbox &
wm_pid=$!
cleanup() { kill "$wm_pid" 2>/dev/null || true; wait "$wm_pid" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
/usr/local/bin/identos-panel2
EOF
chmod +x config/includes.chroot/usr/local/bin/identos-session2
cat > config/includes.chroot/usr/share/xsessions/identos2.desktop <<'EOF'
[Desktop Entry]
Name=IDENT Desktop 2 (Experimental)
Comment=Modular desktop shell with settings
Exec=/usr/local/bin/identos-session2
TryExec=/usr/local/bin/identos-session2
Type=Application
DesktopNames=IDENT
EOF
cat > config/includes.chroot/usr/share/xsessions/identos.desktop <<'EOF'
[Desktop Entry]
Name=IDENT Desktop
Comment=IDENT OS desktop shell
Exec=/usr/local/bin/identos-session
TryExec=/usr/local/bin/identos-session
Type=Application
DesktopNames=IDENT
EOF
# Convert the shipped SVG into a raster background. feh does not reliably decode
# SVG itself on all minimal images. Keep the original artwork too.
mkdir -p config/hooks/normal
cat > config/hooks/normal/0750-identos-wallpaper.hook.chroot <<'EOF'
#!/bin/sh
set -eu
if command -v convert >/dev/null 2>&1; then
  convert -background none -density 96 /usr/share/backgrounds/identos/identos.svg /usr/share/backgrounds/identos/identos.png
elif command -v magick >/dev/null 2>&1; then
  magick /usr/share/backgrounds/identos/identos.svg /usr/share/backgrounds/identos/identos.png
else
  echo "IDENT OS: image converter missing" >&2
  exit 1
fi
EOF
chmod +x config/hooks/normal/0750-identos-wallpaper.hook.chroot
lb build
IMAGE="$(find . -maxdepth 1 -name '*.hybrid.iso' -o -name '*.iso' | head -1)"
[[ -n "$IMAGE" && -s "$IMAGE" ]] || { echo "ERROR: live-build created no ISO" >&2; exit 1; }
cp "$IMAGE" "$OUT/identos-live-amd64.iso"
(cd "$OUT" && sha256sum identos-live-amd64.iso > identos-live-amd64.sha256)
echo "Built $OUT/identos-live-amd64.iso"
