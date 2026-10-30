# IDENT OS base runtime milestone

IDENT OS uses the **Linux kernel and Debian 13 systemd base**. This change gives the live distribution an explicit, testable base-runtime layer. It is not a new kernel or disk installer.

## System components

- `systemd`, `systemd-sysv`: process supervision and boot targets
- `udev`/`systemd-udevd`: kernel device events
- `dbus`: interprocess messages
- `policykit-1`: desktop authorization infrastructure
- `network-manager`: network setup
- `initramfs-tools`, `linux-image-amd64`: kernel and boot tooling
- `locales`, `tzdata`, `sudo`, `passwd`: host configuration and account fundamentals

The live build installs `identos-base-check`, a **read-only** runtime checker, as a restricted `systemd` oneshot service. Logs are accessible with:

```sh
systemctl status identos-base-check.service
journalctl -u identos-base-check.service -b
identos-base-check
```

It also includes runtime tmpfiles configuration and conservative kernel filesystem link protections.

## What base-OS ready does NOT mean

- No validated physical-disk installer or repartitioning
- No verified UEFI + BIOS boot from an installed disk
- No tested non-root account provisioning or secure automatic updates
- No tested recovery partition, disk encryption or rollback
- No tested real-world device compatibility

These are **release blockers**, not marketing footnotes. Build and headless kernel-boot CI must pass; then graphical login, account creation, storage, networking, shutdown/reboot and recovery need full-system QEMU and physical-hardware testing before a base-OS release declaration.

## Next acceptance milestone

Use an isolated virtual disk and build a **separate installer** with explicit disk selection and confirmation, reproducible rootfs creation, bootloader provisioning, account setup and verified rollback. Never experiment with partitioning on the host's main disk.
