# Architecture decision record 0001: boot foundations

**Status:** accepted for Alpha 0.0.1.

IDENT OS starts with the Linux kernel to obtain hardware drivers and an established process model. The first boot artifact is a compressed `newc` initramfs containing a BusyBox command environment. QEMU launches it using an externally supplied x86-64 Linux kernel image. There is no bootloader or disk installer in this milestone.

This is intentionally narrower than a Linux distribution. It establishes a reviewable boot process and build/test boundary before desktop integration. We will not suggest that Wine or Proton are native kernel features: later compatibility work uses user-space projects and per-program configurations, with documented limitations.

**Boundaries:** `rootfs/` is initial user space; `scripts/` builds/tests/runs artifacts; later `desktop/`, `compatibility/`, `network/` and `system/` projects must have independent tests and clear APIs. Any experimental kernel work belongs in a separate research tree and cannot replace the production Linux kernel without a demonstrated userspace compatibility strategy.

**Threat model for this milestone:** no untrusted users or workloads, local QEMU use only, no network and no persistent disks. A root shell is deliberately available for development, and is not production security.

**Release policy:** no production install instructions until update signing, recovery, system isolation, installer rollback and hardware compatibility testing are implemented.
