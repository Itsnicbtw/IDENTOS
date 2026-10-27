# IDENT OS: platform compatibility and product architecture

Status: **target architecture**, not claims about current support.

## Product objectives

IDENT OS is designed to serve three profiles without becoming three incompatible operating systems:

- **Everyday:** safe defaults, simple setup, updates with rollback, accessibility, battery efficiency, browser, games, local file management and intuitive software installation.
- **Developer:** reproducible environments, containers/VMs, compiler toolchains, Git, terminal, language SDKs, API/service testing and diagnostics.
- **Organisation:** device fleet enrolment, policy-as-code, role-based administration, audit logs, patching, encrypted storage, inventory, VPN, remote support and application lifecycle management.

These are opt-in roles/features built on a common reliable core. Enterprise enrolment must never be mandatory for personal use.

## Hardware targets and support tiers

**Tier 1:** modern x86-64 UEFI PCs and laptops. Validate Intel and AMD CPUs, integrated and discrete graphics, NVMe/SATA, USB, audio, Wi-Fi, Ethernet, Bluetooth, suspend/resume and input devices.

**Tier 2:** ARM64 UEFI/SBSA-compatible servers and supported consumer devices. ARM laptops may need device-specific kernels/firmware; do not claim generic ARM64 hardware compatibility.

**Tier 3:** older x86-64 legacy BIOS machines where supported. Optional, limited guarantees.

Future hardware compatibility depends on upstream Linux kernels, firmware, graphics stacks and active validation. There is no technically credible promise of supporting *all* current and future functional hardware.

### Hardware qualification

Maintain a public hardware-compatibility database recording manufacturer/model, firmware version, kernel version, device IDs, graphics and Wi-Fi drivers, suspend/resume, installer outcome, test date and known issues. Never report "supported" without direct tests.

Automate QEMU smoke tests for x86-64 UEFI and legacy boot first, add ARM64 emulation, then dedicated hardware-in-the-loop runners. Test Secure Boot/signatures separately.

## Windows executable compatibility

Windows `.exe` is a file format, not a guarantee of executable compatibility. Build a compatibility broker that classifies PE binaries, selects native Wine or Proton profiles where available, isolates per-application prefixes, displays compatibility and permissions, and offers an explicitly licensed Windows VM fallback.

Target compatibility with ordinary Windows desktop applications and games incrementally, using a tested application database. Kernel-mode Windows drivers, anti-cheat and DRM, special hardware drivers, and selected UWP/software dependencies may never work without native vendor support. Never promise 100% .exe support.

## Development principles

- **Portable:** clear CPU/firmware/platform boundaries rather than x86 assumptions across services.
- **Local-first:** accounts and core operation work offline.
- **Safe:** signed updates, recoverable immutable/transactional base, full-disk encryption, least privilege, sandboxing and auditable changes.
- **Accessible:** keyboard, screen-reader, scaling, reduced-motion and input-device testing are core acceptance criteria.
- **Maintainable:** use existing Linux drivers and standards; build genuinely differentiated interfaces and system services rather than unnecessary driver rewrites.
- **Transparent:** publish limitations and test coverage.
- **Corporate:** policies apply only to enrolled organisational devices with clear owner consent.
- **Decentralised:** signed peer-assisted delivery can distribute bytes; clients independently verify trust and retain offline function.

## Roadmap gates

1. **Reliable live ISO:** Debian-based graphical live environment builds, checksum passes and QEMU boots to a graphical login.
2. **Persistent installation:** installer, persistent encrypted root, recovery, verified upgrades and non-root default account.
3. **Original experience:** custom shell/launcher/settings, application hub, onboarding, accessibility and system diagnostics.
4. **Developer edition features:** containers, toolchain profiles, VMs, terminal integration and reproducibility.
5. **Enterprise edition features:** management daemon, explicit enrolment, configuration profiles, audit, support/updates.
6. **Compatibility broker:** Wine/Proton, PE detection, prefix management, sandboxing and application compatibility database.
7. **Broader hardware:** x86-64 hardware matrix, ARM64 experimentation and continuous regression testing.

**Release labels:** prototype -> alpha -> beta -> release candidate -> stable. A passing ISO build alone is not a stable OS.
