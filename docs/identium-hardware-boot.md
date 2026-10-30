# IDENTIUM hardware boot (experimental)

This work adds a generic hardware kernel config overlay and a BIOS/UEFI-capable GRUB rescue ISO generation path. The ISO boots the **minimal unauthenticated IDENTIUM emergency rootfs in RAM**, not the full IDENT graphical desktop. It does not install, persist, enrol firmware keys, or write to internal drives.

Build the IDENTIUM kernel and separate independent initrd first. Then:

```sh
bash kernel/make-boot-iso.sh build/identium-kernel/arch/x86/boot/bzImage build/identium-independent-initrd.cpio.gz build/identium-rescue.iso
```

Output is a file that may later be written to removable media with a separate, carefully verified imaging tool. **This script intentionally does not write USB sticks or disks.**

Hardware testing is not established by a QEMU boot. UEFI boot also requires compatible EFI GRUB tooling, firmware trust policy and Secure Boot considerations. The ISO is expected to be rejected with Secure Boot enabled unless a trusted signed chain is added.

Use a spare machine, avoid devices containing important data, and test network-free. The emergency shell has no authenticated login and is not suitable as a deployed operating system.
