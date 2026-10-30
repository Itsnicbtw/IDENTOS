# IDENT OS boot management and distribution ownership

The `identos-bootctl` command reports BIOS/UEFI mode, the systemd default target and systemd-boot entries if available. It is **read-only**: it does not rewrite GRUB, change firmware NVRAM, select another boot device, or modify disks.

```sh
identos-bootctl
identos-bootctl --json
```

Booting is still implemented by Debian Live, GRUB and the Linux kernel. These are intentionally retained while the project develops and tests its own interfaces.

The machine-readable `/usr/share/identos/distribution.json` describes the IDENT-specific distribution identity and its upstream dependencies. The system is an IDENT-maintained Linux distribution **based on Debian**, not an independent from-scratch OS. Replacing the boot process or package foundation requires parallel images, verified rollback and BIOS/UEFI virtual-machine tests before switching defaults.

## Independent-base roadmap
1. Versioned rootfs/build interfaces and audited package provenance.
2. Reproducible minimal IDENT rootfs assembled in isolated builders with tracked SBOM.
3. Signed package and update repository, with upgrade/rollback tests.
4. An optional IDENT boot entry alongside known-good GRUB fallback; validate secure boot before enabling it.
5. Fully tested installed-disk boot, user account setup and recovery on isolated VM disks.

Never rewrite firmware or repartition the host as part of the build.
