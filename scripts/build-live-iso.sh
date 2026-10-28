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
xfce4-goodies
xfce4-whiskermenu-plugin
xfce4-notifyd
xfce4-power-manager
xserver-xorg-input-libinput
xserver-xorg-video-all
xserver-xorg-video-qxl
xserver-xorg-video-fbdev
adwaita-icon-theme
xcursor-themes
lightdm
network-manager
network-manager-gnome
sudo
firefox-esr
zenity
xdg-utils
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

# Usable graphical defaults, with browser selection that never claims missing
# proprietary or privacy-sensitive browsers are magically installed.
mkdir -p config/includes.chroot/etc/skel/Desktop
mkdir -p config/includes.chroot/etc/lightdm/lightdm.conf.d

cat > config/includes.chroot/etc/lightdm/lightdm.conf.d/60-identos.conf <<'EOF'
[Seat:*]
user-session=xfce
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
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;
EOF
chmod +x config/includes.chroot/etc/skel/Desktop/identos-terminal.desktop

# Default desktop artwork and useful diagnostics for the graphical edition.
mkdir -p config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p config/includes.chroot/usr/share/backgrounds/identos
cat > config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/identos/identos.svg"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
cat > config/includes.chroot/usr/share/backgrounds/identos/identos.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
<defs><linearGradient id="b" x2="1" y2="1"><stop stop-color="#101523"/><stop offset="1" stop-color="#26395b"/></linearGradient></defs>
<rect width="1920" height="1080" fill="url(#b)"/>
<circle cx="1510" cy="470" r="390" fill="#5474aa" opacity=".10"/>
<text x="100" y="920" fill="#e7edf8" font-family="sans-serif" font-size="70" font-weight="700">IDENT OS</text>
<text x="104" y="970" fill="#a9bbd7" font-family="sans-serif" font-size="26">Developer Live Edition</text>
</svg>
EOF
cat > config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Default"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="workspace_count" type="int" value="4"/>
  </property>
</channel>
EOF
cat > config/includes.chroot/usr/local/bin/identos-graphics-check <<'EOF'
#!/bin/sh
set -u
echo "IDENT OS graphics check"
printf 'Session: %s\n' "$XDG_CURRENT_DESKTOP"
printf 'Display: %s\n' "$DISPLAY"
command -v Xorg || true
command -v xfce4-session || true
command -v firefox-esr || true
command -v glxinfo >/dev/null 2>&1 && glxinfo -B 2>/dev/null || true
echo "Graphics diagnostics complete."
EOF
chmod +x config/includes.chroot/usr/local/bin/identos-graphics-check
cat > config/includes.chroot/usr/share/applications/identos-graphics-check.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=IDENT OS Graphics Diagnostics
Exec=xfce4-terminal --hold --command=identos-graphics-check
Icon=video-display
Terminal=false
Categories=System;
EOF
lb build
IMAGE="$(find . -maxdepth 1 -name '*.hybrid.iso' -o -name '*.iso' | head -1)"
[[ -n "$IMAGE" && -s "$IMAGE" ]] || { echo "ERROR: live-build created no ISO" >&2; exit 1; }
cp "$IMAGE" "$OUT/identos-live-amd64.iso"
(cd "$OUT" && sha256sum identos-live-amd64.iso > identos-live-amd64.sha256)
echo "Built $OUT/identos-live-amd64.iso"
