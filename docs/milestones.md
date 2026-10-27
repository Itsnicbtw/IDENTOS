# Milestones

## Alpha 0.0.1: boot engineering (this change)

- [x] Define Linux-first architecture and scope
- [x] Build an initramfs with executable PID 1
- [x] Provide QEMU launcher, serial console and no-network default
- [x] Provide syntax and archive checks
- [ ] Verify boot in QEMU on CI and a second x86-64 host
- [ ] Add reproducible kernel provenance and pinned build toolchain

## Alpha 0.0.2: integration

- [ ] Add deterministic containerised build environment
- [ ] Add boot-time automated console test
- [ ] Add early logging, crash capture and halt diagnostics
- [ ] Implement read-only root filesystem planning

## Later

- [ ] Wayland desktop and application launcher
- [ ] Installer and atomic system updates
- [ ] Wine application runtime integration
- [ ] Encrypted local-first peer sync
- [ ] Secure supply-chain signing and verification
