# IDENT OS

[![IDENT OS CI](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml/badge.svg)](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml)
[![License: Apache-2.0](https://img.shields.io/badge/Original%20code-Apache--2.0-blue)](LICENSE)
![Stage](https://img.shields.io/badge/stage-developer%20prototype-orange)

**IDENT OS** is an open-source, Linux-based operating-system experiment pursuing a new desktop, Windows application compatibility and optional decentralised services.

> **Status:** Developer prototype. The ISO is a minimal, root-operated command-line environment, not a secure installer, full desktop, or Windows replacement.

## Build a bootable ISO

On a suitable Debian/Ubuntu **x86-64** build machine:

```bash
sudo apt-get update
sudo apt-get install -y busybox cpio gzip qemu-system-x86 grub-pc-bin grub-common xorriso mtools e2fsprogs linux-image-amd64
KERNEL="$(find /boot -maxdepth 1 -name 'vmlinuz-*' -type f | head -1)" bash scripts/build-iso.sh
bash scripts/run-iso.sh
```

The ISO is produced at `build/identos-dev-x86_64.iso`. QEMU automatically creates `build/identos-data.ext4` (256 MiB) when absent and attaches it as a virtual disk. IDENT OS mounts it at `/data` if the kernel supports virtio and ext4. Preserve that disk file across QEMU launches to retain files. The rest of the initramfs is temporary and resets on reboot.

**On a Chromebook:** Run the GitHub Actions pipeline instead of using local storage. Successful builds produce a downloadable ISO artifact in the workflow run. The ChromeOS Linux container may not expose a usable kernel or support accelerated nested virtualisation.

## Developer features

| Capability | Status |
|---|---|
| Bootable GRUB ISO | Source implemented; CI verification required |
| Minimal Linux boot shell and diagnostics | Implemented: memory, uptime, block devices |
| Optional persistent ext4 /data | Implemented; runtime verification required |
| Persistent file commands | save/read/files/delete/nano in the boot console |
| Python 3 and Node.js | Bundled command-line runtimes |\n| Developer toolchain | Git, GCC/G++, Make, curl, tar, npm and pip modules bundled; runtime verification pending |\n| Automated ISO/QEMU checks | Configured in GitHub Actions |
| Desktop, installer, secure user sessions | Not implemented |
| Wine, Proton and .exe support | Planned |
| Peer-to-peer synchronisation | Planned |

## Boot console\n\nAt the `identos#` prompt, try `help`, `memory`, `uptime`, `devices`, `storage`, or `files`. With a persistent disk attached, `save hello hello-world`, `read hello`, and `delete hello` manage files in `/data`. `shell` opens the BusyBox shell. This is a development console running as root, not a secure multiuser terminal.\n\n## Text editor

The boot ISO includes GNU Nano. With the persistent QEMU disk mounted, type `nano notes.txt` at the `identos#` prompt to edit `/data/notes.txt`. Use Ctrl+O to save and Ctrl+X to exit. The Nano command accepts simple filenames only; it will not edit arbitrary host paths. From `shell`, use `nano /data/notes.txt` directly. The image currently uses a serial VT100 terminal, so the editor is text-only.

## Python and Node.js

The development image bundles the build host's Python 3 runtime, standard library and Node.js executable with their linked libraries. Use `python3` or `node` for their interactive environments, or edit scripts on the persistent drive and run them from the `identos#` prompt:

```text
nano hello.py
python3 hello.py
nano hello.js
node hello.js
```

The development image now attempts to include Git, GCC/G++, Make, curl, tar, npm and Python pip modules without a separate user installation. This substantially increases the image size. Toolchains and package managers rely on many filesystem conventions, network facilities and certificates that the small initramfs may still lack. **Installed in the image does not mean verified functional:** CI boot and compile/package-manager tests are still required before declaring this a complete development environment.

## Contribute

**Public contributions are welcome.** Fork, create a topic branch and open a pull request. All PRs trigger the CI pipeline. See [CONTRIBUTING.md](CONTRIBUTING.md). Maintainers must review contributions before merging; CI runs alone do not automatically enforce merge restrictions.

To require review and passing checks, the repository owner must enable branch rulesets in GitHub Settings. See [contribution policy](CONTRIBUTING.md).

## Licensing

Original source files are under [Apache-2.0](LICENSE) unless otherwise indicated. Linux and BusyBox remain under their respective open-source licences. Kernel binaries included in the ISO and any further redistributions require appropriate notices and compliance with applicable GPL source-availability requirements.
