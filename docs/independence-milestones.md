# IDENT OS independence and installation milestones

This is an acceptance plan, not a declaration of completion.

## Milestone 1: Independently assembled minimal rootfs (prototype)
`independent/build-rootfs.sh` constructs a small file hierarchy with IDENT-specific PID 1 init, local identity files and an audited, SHA-256-pinned statically linked BusyBox. It does not use Debian live-build or debootstrap. **It still depends on upstream BusyBox and the Linux kernel, and does not constitute a self-hosted distribution.**

Example using an independently vetted static BusyBox binary:

```sh
BUSYBOX_STATIC=/path/to/busybox-static BUSYBOX_SHA256=<verified-64-hex-sha256> \
  bash independent/build-rootfs.sh build/identos-independent-rootfs.tar.gz
```

Only use the output in an isolated VM with a compatible Linux kernel supplied separately. It currently has an unauthenticated root emergency console and MUST NOT be installed on ordinary hardware.

## Milestones not yet completed

| Requirement | Acceptance evidence required |
|---|---|
| Independent full rootfs | Boot, network, storage, user accounts and package provenance; reproducible build without Debian runtime packages |
| Installer | Protected image-file dry run, isolated-disk QEMU installation, UEFI and BIOS boot, explicit physical-drive confirmation and backup/recovery tests |
| Own package repositories | Hosted origin, metadata signing, source and binary publishing, authenticated repository rotation, clean install and update tests |
| Secure Boot | Controlled signing keys, verified signed EFI artifacts, shim/UKI trust chain and hardware enrollment tests; never auto-enrol firmware keys |
| Rollback | A/B or snapshot design, signed update, deliberate failure injection and proven automatic fallback in VM |
| Persistence | Boot installed ext4 rootfs, create non-root user, reboot and demonstrate checksummed file and system state survive |

## Safety

No physical disks are partitioned by this repository milestone. No key enrolment, firmware writes, public package repository or recovery guarantee is implemented. The Debian-based graphical ISO remains the known-good development track while independent components mature.


## Experimental boot smoke test

The independently assembled rootfs can now be repackaged as a Linux initramfs and booted directly using an externally provided Linux kernel in an isolated QEMU instance. This path does not use the Debian Live root filesystem, and QEMU is intentionally launched without any disks or networking.

```sh
sudo apt-get install busybox-static cpio qemu-system-x86
export BUSYBOX_STATIC="$(command -v busybox)"
export BUSYBOX_SHA256="$(sha256sum "$BUSYBOX_STATIC" | cut -d' ' -f1)"
bash independent/build-rootfs.sh build/identos-independent-rootfs.tar.gz
bash independent/build-initrd.sh build/identos-independent-rootfs.tar.gz build/identos-independent-initrd.cpio.gz
bash independent/boot-qemu.sh /path/to/vmlinuz build/identos-independent-initrd.cpio.gz
```

The CI integration smoke test must see the IDENT init banner after kernel boot. This **does not demonstrate an installed-disk boot, a persistent user session, secure multiuser login, or rollback from a failed actual boot**. The bare emergency shell is unauthenticated and appropriate only in isolated VMs. Hardware installation remains blocked.
