# IDENT OS alpha release readiness

This document is a **gate**, not a claim that the gates are complete. IDENT OS is a Debian-based experimental live system, not a secure Windows replacement.

## Gates required before an alpha release

| Gate | What must be demonstrated | Current evidence |
|---|---|---|
| Source quality | CI, shell tests, Python syntax, package checks | GitHub Actions; verify the exact release commit |
| ISO reproducibility | Build on a clean Debian Trixie builder, record SHA-256, retain package manifest | Partial, builds can depend on external repos |
| Kernel boot | Extract live kernel and initrd, boot via QEMU, capture serial evidence | Automated smoke check |
| Graphical login | LightDM accepts a normal user login; Openbox and IDENT panel start | **Not automated** |
| Mouse, keyboard, display | Application launch, resizing, multiple resolutions, input tests | **Not automated** |
| Persistence | Create a dedicated persistent volume; reboot and verify saved files | **Not verified for graphical release** |
| Installation | Non-destructive guided installer with UEFI/BIOS and recovery checks | **Not implemented** |
| Secure updates | Signed repository metadata, rollback strategy, explicit version pinning | **Not implemented** |
| Accounts and security | Non-root accounts, patch policy, firewall, secret handling and permissions audit | **Requires testing** |
| Windows programs | Wine compatibility matrix across representative .exe programs | **Not implemented** |
| Native .idt | Package authenticity, sandboxing, lifecycle and update semantics | **Not complete** |
| Hardware | GPU, Wi-Fi, audio, suspend, power, touchpad and storage tests on several devices | **Not verified** |
| Performance | Compare memory, idle CPU, disk and boot time on the *same* hardware against baseline distributions | **Benchmark utility available; no comparison yet** |

## Local commands

```bash
bash scripts/identos-readiness.sh --host
bash scripts/identos-readiness.sh --image  # after a build
bash tests/test-release-readiness.sh
```

Inside an IDENT OS live session: `identos-system-report` and `identos-benchmark`.

## Release policy

A green GitHub Actions workflow is evidence of a source/build/limited kernel test only. Do not label the system installer-ready, Windows-compatible, hardened, or hardware-universal until those capabilities have independent tests. No unattended partition writes, background driver downloads or automatic firmware flashing. Security updates and release signing must be designed before distributing a primary-use system.
