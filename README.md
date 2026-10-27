# IDENT OS

An experimental, open-source desktop operating-system project. The long-term goals are a custom Linux-based desktop, Windows application compatibility, and local-first, decentralised services. An independent kernel may be researched separately; it is **not** part of this boot image.

## Alpha 0.0.1: boot foundation

This repository currently builds a minimal **x86-64 Linux initramfs** with BusyBox and a purpose-written `/init`. It is a bootable command-line engineering milestone, **not** a complete desktop OS, installer, secure operating environment, or Windows-compatible product.

### Requirements (Debian/Ubuntu host)

```sh
sudo apt-get update
sudo apt-get install -y busybox cpio gzip file qemu-system-x86
```

A compatible **x86-64 Linux bzImage** is required. On a conventional Debian host it may be `/boot/vmlinuz-$(uname -r)`; ChromeOS Linux containers often do not expose a kernel image and will require one supplied explicitly. The initramfs builder bundles BusyBox's dynamically linked libraries when needed, from the build host. Only run images using libraries from a trusted system.

### Build and boot

```sh
./scripts/build-initramfs.sh
KERNEL=/boot/vmlinuz-$(uname -r) ./scripts/run-qemu.sh
```

If the kernel is elsewhere: `KERNEL=/path/to/x86_64/bzImage ./scripts/run-qemu.sh`.

QEMU runs without disk or network by default. At the `identos#` prompt, try `help`, `info`, `mount`, `uname -a` and `poweroff`. Hit Ctrl+A then X to exit QEMU's `-nographic` console. You can also use `timeout 15 ./scripts/run-qemu.sh` for limited smoke testing.

### Checks

```sh
./scripts/test.sh
```

### Architecture roadmap

1. **Boot and recovery:** initramfs, reproducible builds, hardware testing, verified updates.
2. **Desktop:** Wayland compositor, shell, accessibility, settings, applications.
3. **Compatibility:** Wine/Proton integration, per-application sandboxes, diagnostics.
4. **Decentralisation:** optional encrypted local-first sync, signed peer-delivered updates and repository federation.
5. **Independent kernel R&D:** isolated research only, with explicit interfaces and realistic driver cost.

Security note: this minimal root shell is for isolated VM development only. Never deploy it as a multi-user system. No update signatures, hardened sandboxing, or secure boot chain exist yet.

## Contributions and licensing

The repository's existing root `LICENSE` is Apache License 2.0, applying to original project code unless otherwise indicated. Linux, BusyBox, Wine, and other third-party components retain their own licences; distributing an ISO with them requires complying with those licences and providing applicable source and notices. The kernel is GPL-2.0-only (with additional licensing nuances), not Apache-licensed.

See [docs/architecture.md](docs/architecture.md) and [docs/milestones.md](docs/milestones.md).
