# IDENT OS low-level scaling foundation

## Scope of PR #30
This milestone introduces versioned, machine-readable platform capability detection and release artifact integrity metadata. These interfaces are deliberately small and testable. They **do not** replace Linux, the Debian package manager, a bootloader, or the desktop compositor.

### Hardware feature reporting
Run `identos-capabilities --pretty` in the live image. This only reads procfs, sysfs, and device existence, never writes devices or contacts a server. JSON schema version 1 reports UEFI, CPU virtualization flags, KVM device access, TPM device existence, DRM subsystem presence, battery, cgroup v2, architecture and installed RAM. A reported capability is **not** a guarantee that it works.

### Build artefact integrity
Use `python3 scripts/identos-release-manifest.py --iso build/identos-live-amd64.iso --manifest build/release-manifest.json` to describe the ISO by byte length and SHA-256. Use `--verify` to detect changes. **Hash manifests are not digital signatures** and offer no protection against an attacker replacing both files. Trustworthy distribution requires signing keys, transparency and a documented release process.

### Scale plan with measurable gates
1. Freeze versioned device, app, system-service and package interfaces, with integration tests.
2. Add GPU and audio diagnostics, input-device tests and driver fallback in real VMs and hardware.
3. Implement an installer with explicit disk selection, UEFI/BIOS tests, secure user creation, backup and rollback.
4. Design A/B or snapshot-based system updates with independently verifiable signatures and recovery.
5. Add performance budgets for boot time, idle CPU, RAM, energy, and browser startup across representative machines; publish repeatable datasets.
6. Gradually replace Openbox/Xorg services with IDENT components **only after** parity, accessibility and failure recovery tests.

No benchmark currently establishes IDENT OS as faster than competing systems. This is an engineering baseline, not a production-scale claim.
