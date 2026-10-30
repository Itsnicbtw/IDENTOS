# IDENTIUM: independent-base programme

**IDENTIUM** is the working name for IDENT OS's independent-base programme. It is **not yet a Debian replacement**. The graphical IDENT OS image remains based on Debian Trixie; see the separate independent rootfs development branch for prototype work.

## Secure Boot preparation

`identium/secureboot.sh` provides explicit PE/COFF EFI binary signing and signature verification with `sbsign` and `sbverify` from `sbsigntool`.

```sh
sudo apt-get install sbsigntool
bash identium/secureboot.sh sign --image ./BOOTX64.EFI \
  --key /secure/offline/identium-db.key \
  --certificate /secure/offline/identium-db.crt \
  --output ./BOOTX64-signed.efi
bash identium/secureboot.sh verify --image ./BOOTX64-signed.efi \
  --certificate /secure/offline/identium-db.crt
```

Keys are **never generated, committed, exported to CI or enrolled in firmware** by these scripts. Keep keys offline, encrypted and access controlled. A signed EFI binary is not automatically trusted by a machine's firmware.

## Work still required for functional Secure Boot

1. Produce an EFI bootloader or unified kernel image that uses an auditable boot chain.
2. Define signing-key ownership, rotation, revocation and recovery.
3. Decide between Microsoft-compatible shim distribution and owner-enrolled keys; account for firmware vendor behaviours and licences.
4. Verify all boot stages (including kernel, initrd, modules and command line) against an explicit threat model.
5. Test validation and rejection of tampered binaries under OVMF with Secure Boot enabled, then on opt-in hardware.
6. Build reproducible, independently provisioned rootfs and package update infrastructure.

No firmware key modification or automatic installation should happen before those tests succeed. This is signing *infrastructure*, not a claim of end-to-end Secure Boot support.
