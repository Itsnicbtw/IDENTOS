<div align="center">

# IDENT OS

**A Linux-based desktop operating system in development, built for people, developers and organisations.**

[![Core CI](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml/badge.svg)](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml)
[![Desktop ISO](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/live-desktop.yml/badge.svg)](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/live-desktop.yml)
[![License: MIT](https://img.shields.io/badge/Original%20code-MIT-087f5b)](LICENSE)
![Status](https://img.shields.io/badge/status-early%20alpha-f59e0b)

[Overview](#overview) · [Get started](#get-started) · [Development](#development) · [Roadmap](#roadmap) · [Contributing](#contributing)

</div>

> [!IMPORTANT]
> **Early alpha / experimental software.** IDENT OS is not ready for production deployment or installation on a primary computer. Not all builds are guaranteed to boot. Use a disposable VM and keep backups.

## Overview

**IDENT OS** is an open-source effort to create a cohesive desktop experience using the Linux ecosystem rather than rewriting its mature hardware-driver foundation. Our long-term direction is one platform with three complementary experiences:

| Experience | Direction |
|---|---|
| **Home** | Familiar, accessible desktop, simple applications, dependable updates and gaming compatibility |
| **Developer** | Fast terminal workflows, programming tools, containers, virtualisation and diagnostics |
| **Enterprise** | Enrolment, policy controls, device administration, fleet visibility and auditable security |

**These are product goals, not a list of shipped features.** The present repository contains two experimental boot targets: a minimal command-line Linux environment and a Debian 13/XFCE-based graphical live image.

## What works today?

| Capability | Current state |
|---|---|
| Minimal Linux initramfs and GRUB ISO | Implemented; tested in QEMU by core CI |
| Minimal console commands and optional ext4 data disk | Implemented; see [core boot documentation](docs/boot-validation.md) |
| Debian 13 live desktop with XFCE | Image build and checksum validation in GitHub Actions; graphical login verification remains ongoing |
| Live desktop developer tooling and hardware report | Included in the graphical build configuration |
| Graphical VM boot helper | In development; check [pull requests](https://github.com/Itsnicbtw/IDENTOS/pulls) |
| Home persistence image generator | Prototype; not a full installer |
| **.idt** IDENT application bundles | Prototype Python runtime and explicit launch; no publisher authentication or sandbox |
| Native IDENT shell / graphical installer | Not yet shipped |
| General Windows `.exe` support | Roadmap; not implemented |
| Broad hardware certification and enterprise management | Roadmap; not implemented |

Progress and test status are visible through [GitHub Actions](https://github.com/Itsnicbtw/IDENTOS/actions). An ISO compiling is **not** proof that it has been tested on physical hardware.

## Get started

### Download a development image

1. Open [Live Desktop ISO workflow](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/live-desktop.yml).
2. Choose a **successful run** from `main`, and download the `identos-live-amd64` artifact.
3. Extract `identos-live-amd64.iso` and `identos-live-amd64.sha256`, then verify the checksum.

```bash
cd build
sha256sum -c identos-live-amd64.sha256
```

GitHub Actions artifacts are temporary build outputs, **not stable production releases**. Official releases, when available, will be published through [Releases](https://github.com/Itsnicbtw/IDENTOS/releases).

### Run the graphical ISO safely

Use a virtual machine first. On Debian/Ubuntu with QEMU:

```bash
sudo apt-get install qemu-system-x86 ovmf
bash scripts/boot-live-vm.sh
```

The VM launcher is being added in [PR #13](https://github.com/Itsnicbtw/IDENTOS/pull/13); until merged, use that PR branch or the instructions in [the boot guide](https://github.com/Itsnicbtw/IDENTOS/blob/feat/bootable-live-vm/docs/boot-live-vm.md). See [live-desktop setup](docs/live-desktop.md) for build and persistence details.

### Build the minimal command-line ISO

The minimal ISO is a separate testing target. It is not the graphical live desktop. It is built and boot-tested by [core CI](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml). For source/build details, see [scripts/](scripts/) and [boot validation](docs/boot-validation.md).

## Development

The project currently builds around **Debian 13, Linux, XFCE, BusyBox, GRUB, Python, Bash and GitHub Actions**. The modular design allows us to evolve toward a distinct desktop and application model without promising a new kernel or universal hardware compatibility.

- **Boot and images:** `scripts/`, `rootfs/`, `.github/workflows/`
- **App format:** `tools/idt.py`, `docs/idt-format.md`
- **Architecture and targets:** [Platform strategy](docs/platform-strategy.md)
- **Build verification:** [GitHub Actions](https://github.com/Itsnicbtw/IDENTOS/actions)
- **Known limitations:** [Live desktop](docs/live-desktop.md) and [boot validation](docs/boot-validation.md)

## Roadmap

1. **Prove graphical boot:** bootloader, kernel, live userspace, display manager and interactive desktop.
2. **Safe installation and persistence:** disposable-VM installer tests, non-root accounts, recovery, and disk safety.
3. **IDENT desktop experience:** launcher, settings, accessibility, notifications and consistent design.
4. **Developer workflows:** environment setup, containers, virtual machines and tooling integrations.
5. **IDT ecosystem:** trusted publishers, sandboxing, permissions, software installation and updates.
6. **Compatibility and enterprise:** progressive Wine/Proton application support, device enrolment and managed fleets.

Roadmap items are aspirational until code and repeatable tests prove them.

## Contributing

Contributions, technical reviews and reproducible bug reports are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md), describe your hardware or QEMU configuration, and include logs for boot problems. Avoid uploading private data or giant ISO files into Git history.

Security issues should follow [SECURITY.md](SECURITY.md), not public exploit reports.

## Licence

Original IDENT OS code that project copyright holders have authorised for relicensing is made available under the [MIT License](LICENSE). **Historical Apache-2.0 contributions and third-party packages retain their own applicable licences.** Read [licensing details](docs/licensing.md) before redistributing a full system image.

---

<div align="center">
  <sub>IDENT OS · Developed as part of the IDENT technology ecosystem · Built in the open</sub>
</div>
