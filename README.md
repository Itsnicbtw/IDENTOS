# IDENT OS

[![IDENT OS CI](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml/badge.svg)](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/checks.yml)
[![License: Apache-2.0](https://img.shields.io/badge/Original%20code-Apache--2.0-blue)](LICENSE)
![Stage](https://img.shields.io/badge/stage-developer%20prototype-orange)

**IDENT OS** is an open-source, Linux-based operating-system experiment pursuing a new desktop, Windows application compatibility and optional decentralised services.

> **Status:** Experimental graphical Linux distribution. IDENT Desktop is the intended default session, powered by Xorg and Openbox. Full ISO boot and desktop interaction remain unverified.

## Build IDENT OS (graphical edition)

This is the **primary** IDENT OS experience. On a Debian/Ubuntu x86-64 build host:

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap squashfs-tools xorriso qemu-system-x86
sudo bash scripts/build-live-iso.sh
bash scripts/boot-live-vm.sh
```

The expected output is `build/identos-live-amd64.iso`. It contains LightDM, the IDENT Desktop session, the custom panel, app launcher, Firefox ESR, file management, networking and development tools.

**Persistent user files** require an explicitly configured persistence image. Running without one means changes made during the live session can disappear on shutdown.

## Legacy boot-console diagnostic ISO

The old `build/identos-dev-x86_64.iso` still exists for testing the minimal initramfs, serial console and recovery commands. It is **not** the default IDENT OS user experience and should not be distributed as the graphical desktop image.

## Developer features

| Capability | Status |
|---|---|
| Bootable GRUB ISO | Source implemented; CI verification required |
| Minimal Linux boot shell and diagnostics | Implemented: memory, uptime, block devices |
| Optional persistent ext4 /data | Implemented; runtime verification required |
| Persistent file commands | save/read/files/delete/nano in the boot console |
| Python 3 and Node.js | Bundled command-line runtimes |\n| Developer toolchain | Git, GCC/G++, Make, curl, tar, npm and pip modules bundled; runtime verification pending |\n| Browser selection at boot | Firefox, Chrome, Tor Browser, Aster menu entries; launch not yet supported |\n| Automated ISO/QEMU checks | Configured in GitHub Actions |
| Custom IDENT Desktop | Source implemented; interactive QEMU verification pending |\n| Installer and secure user accounts | Not implemented |
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

## Browser selection (preview)

GRUB now provides a **Browser selection (preview)** submenu for Firefox, Google Chrome, Tor Browser and Aster. Each selection passes `ident.browser=...` to the Linux kernel command line; the early-boot console displays the selected browser and explains that launch is not available yet. **This is a selection interface, not a functional browser boot mode.**

The current ISO does not ship a display server, graphical session, or browser binaries. Those must be integrated and tested before these entries can launch browsers. Aster is intentionally reserved until an approved, compatible build is available. Tor Browser also requires careful profile isolation, networking and privacy validation before it can be provided as a default browsing environment.

## Graphical Live Desktop

The primary IDENT OS image uses Debian Live with IDENT Desktop, not XFCE:

```bash
sudo apt-get install live-build debootstrap squashfs-tools xorriso
sudo bash scripts/build-live-iso.sh
bash scripts/boot-live-vm.sh
```

The graphical live image includes a custom IDENT Desktop session over Xorg/Openbox, graphical login, mouse and keyboard drivers, terminal, file manager, Firefox ESR, browser selection utility, Python 3, Node.js, npm, pip, Git and build tools. The browser chooser launches Firefox ESR; Chrome, Tor Browser and Aster are only offered if installed, otherwise an explicit unavailable message is shown. No browser download is performed automatically. Aster remains a future integration.

**Limitations:** This live ISO has not been built or boot-tested in this change. It is a Debian-based experimental desktop, not an independent kernel or a fully hardened production OS. The other compact ISO remains a text console. Graphical VM needs a display-capable environment and sufficient RAM. Live persistence needs separate configuration.

## Graphics build verification

The separate **IDENT OS Graphical Live ISO** GitHub Actions workflow attempts a complete Debian live-build on graphical changes or manual dispatch. It publishes an ISO artifact only when the build completes. The workflow also checks for the IDENT session and browser launcher in the compressed filesystem and runs a headless QEMU kernel-boot smoke test. These checks do not prove that the graphical login, compositor, mouse or Firefox actually work; those require an interactive QEMU session.

The graphical desktop uses IDENT's own Python/Tk panel, launcher, clock and desktop session, with Openbox handling window management and Xorg/libinput handling mouse and keyboard, and an `identos-graphics-check` command for diagnosing display/session availability.

## IDENT Desktop architecture

The graphical live image uses LightDM to start the `IDENT Desktop` session (`/usr/local/bin/identos-session`). The IDENT-owned shell (`desktop/identos-panel.py`) provides the bottom panel, application menu, clock and terminal/files/browser launchers. **It replaces XFCE as the default desktop session.** Openbox is still used for window movement, decorations and focus, and Xorg supplies rendering and input. This is a first working shell implementation, not a homegrown compositor or fully independent display server. Screen and interactive boot verification remain outstanding.

## Contribute

**Public contributions are welcome.** Fork, create a topic branch and open a pull request. All PRs trigger the CI pipeline. See [CONTRIBUTING.md](CONTRIBUTING.md). Maintainers must review contributions before merging; CI runs alone do not automatically enforce merge restrictions.

To require review and passing checks, the repository owner must enable branch rulesets in GitHub Settings. See [contribution policy](CONTRIBUTING.md).

## Licensing

Original source files are under [Apache-2.0](LICENSE) unless otherwise indicated. Linux and BusyBox remain under their respective open-source licences. Kernel binaries included in the ISO and any further redistributions require appropriate notices and compliance with applicable GPL source-availability requirements.
