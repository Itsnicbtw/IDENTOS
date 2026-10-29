# Persistence and recovery (experimental)

## File-backed persistence, not installation
Live sessions are ephemeral unless a dedicated persistence volume is attached. On a **trusted Linux host** with e2fsprogs and free space, use:

```bash
bash scripts/identos-create-persistence.sh --output ./private-persistence.img --size-mib 4096
bash scripts/boot-live-vm.sh --persist ./private-persistence.img
```

The creation command refuses existing files and block devices. It allocates a new ext4 image labelled `persistence` with `persistence.conf` containing `/ union`. Verify data survives a reboot before trusting it. This volume is **not encrypted**; do not store sensitive credentials.

## Recovery
Keep a copy of valuable files separate from the live overlay. If a session fails, boot IDENT OS without `--persist` to diagnose an unchanged live image. Copy or snapshot the image **only with the VM shut down**. Never run filesystem repair on a mounted image. Do not attempt repairs until backups exist.

## Updates
`identos-update-check` runs `apt-get -s upgrade` only. Actual package upgrades require administrator review and Debian repository integrity. There is no IDENT-specific signed update channel, atomic rollback, or installer at this stage.

## Before installing to physical hardware
A guided disk installer needs explicit drive selection, backup checks, UEFI and BIOS boot verification, secure users, and recovery testing. None is provided in this milestone. Do not `dd` the live ISO onto an internal disk or use a persistence image as a substitute for safe installation.
