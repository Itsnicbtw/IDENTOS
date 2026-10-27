# IDENT OS v1: developer build milestone

**Scope:** v1 refers to the first build pipeline, not an end-user operating system.

## Shipped source
- BusyBox-based x86-64 initramfs with custom PID 1 command prompt.
- Scripted initramfs creation and static archive validation.
- QEMU serial-console boot smoke test.
- GitHub Actions pipeline installing a test Linux kernel, booting the image, and uploading the initramfs artifact.

## Build
On Debian/Ubuntu x86-64:

```sh
sudo apt-get update
sudo apt-get install -y busybox cpio gzip qemu-system-x86 linux-image-amd64
bash scripts/test.sh
KERNEL="$(find /boot -maxdepth 1 -name 'vmlinuz-*' -type f | head -1)" bash scripts/smoke-qemu.sh
```

The initramfs does not include the Linux kernel. A kernel must be supplied to run it. The GitHub artifact is an **initramfs**, not an ISO or installer.

## Verification gates
1. Shell scripts pass syntax checks.
2. Initramfs is generated and can be decompressed.
3. Archive contains `/init`, BusyBox, and an executable shell link.
4. QEMU boots with a supplied Linux kernel and the serial console displays the IDENT OS prompt.

## Not yet included
Graphical shell, network stack configuration, installer, disk persistence, sandboxing, Wine/Proton, decentralised services, secure boot, release signatures and a custom kernel.

## Next
Move the build into a pinned container, produce a bootable ISO from the kernel and initramfs, add a dedicated non-root developer account and recovery paths, then start graphical shell R&D.
