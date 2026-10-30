# IDENT OS

[![CI](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml/badge.svg)](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml)
[![Graphical ISO](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/graphics.yml/badge.svg)](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/graphics.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
![Status: Experimental](https://img.shields.io/badge/status-experimental-orange)

**IDENT OS** is an experimental, Debian-based Linux operating system project focused on a developer-friendly desktop, transparent system tools and eventually deeper IDENT-native components.

> **Current state:** Development prototype. Graphical ISO generation, source checks and a headless kernel boot test run in CI. Interactive desktop operation, physical hardware support, installation, security hardening and persistence still require further verification. Do not use as your only operating system.

## At a glance

| Area | Current implementation |
|---|---|
| Base | Debian 13 (Trixie) Live, Linux kernel, x86-64 |
| Display and window management | Xorg, libinput, Openbox |
| Desktop 1 | Python/Tkinter panel; default LightDM session and fallback |
| Desktop 2 | **Native C/GTK3** panel, app actions, clock and settings; optional experimental LightDM session |
| Applications | Firefox ESR, file manager, terminal, Rofi launcher, developer tools |
| Diagnostics | Hardware capability JSON, local system report, performance utilities |
| Live persistence | File-backed persistence tooling; validate before relying on saved data |
| Build verification | Automated scripts, C compilation/self-test, ISO builds and QEMU kernel smoke checks |
| Full disk installer | Not implemented |
| Native `.idt` application ecosystem | Experimental work; not a production-ready package system |
| Windows `.exe` compatibility | Planned, **not shipped as a working compatibility layer** |
| IDENT-native compositor/kernel | Future research, not implemented |

## Getting started

Use a **virtual machine** first. The graphical ISO is the primary desktop build.

### Build the graphical live ISO

On a suitable Debian/Ubuntu x86-64 build host with sufficient disk space:

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap squashfs-tools xorriso qemu-system-x86
sudo bash scripts/build-live-iso.sh
```

The expected artifact is `build/identos-live-amd64.iso`, with its SHA-256 checksum file.

### Boot in QEMU

```bash
bash scripts/boot-live-vm.sh --help
bash scripts/boot-live-vm.sh
```

QEMU needs a graphical display environment. Select **IDENT Desktop** for the existing Python fallback or **IDENT Desktop 2 (Experimental)** for the newer native C panel at the graphical login screen.

### Optional live persistence

A live session is ephemeral unless persistence is correctly configured:

```bash
bash scripts/identos-create-persistence.sh --output ./persistence.img --size-mib 4096
bash scripts/boot-live-vm.sh --persist ./persistence.img
```

The image is **not encrypted**. Back up important data separately, verify persistence across a reboot and read [persistence and recovery](docs/persistence-and-recovery.md). This is not a full operating system installation.

## IDENT Desktop

**Desktop 1** is the default graphical fallback. It uses an IDENT Python panel over Openbox/Xorg.

**Desktop 2** introduces a C/GTK3 panel with application shortcuts, a window selector through Rofi, a clock, configurable clock format and panel height, and per-user settings. The C executable is compiled inside the Debian live build for ABI compatibility. It does **not** replace Openbox, Xorg or Linux.

See [Desktop 2 native development](docs/desktop2-native.md).

## Developer and system tooling

The graphical image includes developer utilities such as Git, Python, Node.js and build tools. The repository also contains:

- `identos-capabilities`: versioned, read-only hardware-capability reporting.
- `identos-system-report`: local diagnostics.
- `identos-benchmark`: basic performance measurements.
- `identos-update-check`: simulated package-upgrade preview, **not** an automatic update service.
- `scripts/identos-release-manifest.py`: SHA-256 artifact integrity manifests, **not digital signatures**.

A separate minimal boot-console ISO remains available for development and recovery experiments; it is not the graphical operating system.

See [low-level architecture](docs/low-level-architecture.md) and [alpha release readiness](docs/alpha-release-readiness.md).

## Verification and limitations

GitHub Actions checks source code, builds ISOs and performs a headless QEMU Linux boot smoke test. These are useful gates, but passing them does **not** establish a usable graphical login, working Wi-Fi/audio/GPU support across hardware, secure installation or production-readiness.

Before a public alpha suitable for regular use, IDENT OS still needs interactive graphical testing, safe installation and account setup, real-hardware compatibility testing, signed updates and rollback, recovery validation, and explicit performance benchmarks.

## Roadmap

1. Stabilise IDENT Desktop 2 with interactive tests, accessibility and multi-monitor support.
2. Add robust installation, account creation, storage and recovery.
3. Develop an independently verified IDENT-native package lifecycle and `.idt` integration.
4. Evaluate Wine-based Windows application compatibility with a published compatibility matrix.
5. Replace selected existing components with IDENT-native implementations only after feature parity, security and performance checks.

## Contributing

Contributions are welcome through pull requests. Please review [CONTRIBUTING.md](CONTRIBUTING.md), include tests where appropriate and avoid claiming features are complete until they have been verified.

## Licence

Original IDENT OS project code is licensed under [Apache License 2.0](LICENSE), unless otherwise stated. Linux, Debian packages and third-party dependencies retain their own licences and redistribution requirements.
