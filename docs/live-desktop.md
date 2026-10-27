# IDENT OS Live Desktop (experimental)

This target uses Debian 13 (Trixie) and XFCE for an **actual graphical Linux live desktop**, alongside the project's custom minimal boot environment. It is **not a new kernel** or fully independent OS.

## Included

- Debian kernel, init system, package manager and hardware support
- XFCE desktop, LightDM, Thunar, terminal and text editor
- NetworkManager and Firefox ESR
- A standard live-user session provided by Debian live-build

## Building

Run in a disposable Debian/Ubuntu build VM with adequate disk space, RAM and network:

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-common
sudo bash scripts/build-live-iso.sh
```

Result: `build/identos-live-amd64.iso` plus SHA256 checksum. The automated workflow can build this remotely, avoiding Chromebook storage use. A full graphical build is much larger and slower than the command-line initramfs prototype.

## Persistence

The boot configuration contains `persistence`. To persist `/home` on a writable drive, create an ext4 partition with label `persistence` and place a file named `persistence.conf` in its root containing:

```text
/home union
```

Keep the persistence partition separate from the read-only ISO. **Never format a disk containing important data.** Test in a VM first. A plain ISO alone is stateless. The live-boot persistence mechanism must be enabled and the partition detected for state to survive reboot.

## Limits and security

This is a Debian-based developer image with IDENT branding and a curated desktop package selection, *not* yet the original IDENT shell, Windows compatibility manager, independent kernel, secure installer, or verified-update architecture. It relies on upstream Debian package security updates. Never claim the prototype has production hardening.
