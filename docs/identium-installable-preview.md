# IDENTIUM installer and Windows compatibility preview

## UEFI/GPT installation into a disposable virtual disk

`independent/install-vm-image.sh` creates a **new raw regular-file disk** with a GPT partition table, 256 MiB EFI System Partition, ext4 root partition, and an EFI GRUB bootloader alongside an IDENTIUM kernel and initramfs. It never points a write operation at physical disks. It requires `libguestfs-tools`, `grub-efi-amd64-bin`, `grub-common`, a validated independent rootfs archive, and existing IDENTIUM kernel/initrd artifacts.

```sh
bash independent/install-vm-image.sh \
  --kernel build/identium-kernel/arch/x86/boot/bzImage \
  --initrd build/identium-boot-initrd.cpio.gz \
  --rootfs build/identium-boot-rootfs.tar.gz \
  --output build/identium-uefi-vm.img --size-mib 2048
```

Boot the image only using a disposable, separately provided OVMF **UEFI** firmware in QEMU. The EFI loader is not signed, so Secure Boot must be off for this experimental image. BIOS is unsupported in this new installer. This is a proof-of-concept disk image with an unauthenticated emergency root console, not a safe general-purpose install. **Do not write it to physical drives.** Actual boot/reboot and persistence across reboot must be demonstrated before declaring the installer operational.

## Windows .exe compatibility

On the **Debian-based graphical IDENT OS Live** edition, Wine is included as a Windows application compatibility layer. Run `identium-run-exe /path/to/program.exe`. It is not a Windows kernel and compatibility varies by application; Wine programs have the user's file permissions and are not sandboxed.

The independent BusyBox-based IDENTIUM rootfs **does not yet include Wine or its graphics/32-bit runtime**. Porting the desktop, runtime loader, libraries, dependencies, graphics/audio APIs and safe app provisioning to that independent edition is separate work.


## Launch a downloaded VM image

When the `IDENTIUM VM Installer Integration` GitHub Actions job is **successful**, download the `identium-uefi-vm-developer-preview` artifact from that run and extract the `.img` file. On Ubuntu install `qemu-system-x86` and `ovmf`:

```sh
bash independent/run-identium-vm.sh --disk path/to/identium-installer-test.img
```

For the more complete existing graphical IDENT OS (Debian-based), obtain the live desktop ISO from its build workflow and run:

```sh
bash independent/run-identium-vm.sh --iso path/to/identos-live-amd64.iso
```

These are two **different** environments. The independent IDENTIUM disk currently reaches an experimental console only if the UEFI boot test passes, with no authenticated login or independent Wine installation. The graphical ISO is the usable desktop build, but remains Debian-based. Keep Secure Boot disabled for unsigned experimental images. Use disposable VM copies only.
