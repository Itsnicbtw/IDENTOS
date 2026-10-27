# IDENT OS boot validation

The project uses distinct stages:

1. **Static image build**: ISO exists; checksum validates.
2. **VM launch**: QEMU accepts and runs the image without immediately failing.
3. **Kernel boot**: a serial log or guest probe proves Linux reached early userspace.
4. **Desktop boot**: a guest-side systemd probe proves the graphical display manager is active.
5. **Interactive desktop**: a real graphical session is exercised with keyboard, mouse, networking, and file persistence across reboot.

`scripts/smoke-live-qemu.sh` currently implements **stage 2 only**. A successful VM launch is not evidence of a functional desktop. Later CI must supply a guest-side boot marker and graphical integration tests.

## Usage

```bash
ISO=build/identos-live-amd64.iso bash scripts/smoke-live-qemu.sh
```

The script uses emulation without KVM and runs without network access. It intentionally does not write to the host disk.
