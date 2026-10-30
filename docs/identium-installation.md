# IDENTIUM installation status

The current installer prototype writes an **ext4 filesystem inside a newly created regular .img file**. It does not partition, format or install onto a physical drive and is not a bootable installed system. Booting still requires a separate kernel and bootloader.

## Isolated image workflow

```sh
BUSYBOX_STATIC=/path/to/verified/busybox BUSYBOX_SHA256=<sha256> \
  bash independent/build-rootfs.sh build/identos-independent-rootfs.tar.gz
bash independent/build-vm-disk.sh \
  --rootfs build/identos-independent-rootfs.tar.gz \
  --output build/identium-root.img --size-mib 2048
```

The image is an ext4 filesystem, not a complete GPT/EFI disk. The root shell in the minimal build has **no login authentication**, so do not install it on a network-connected or shared computer.

CI tests whether the image can store and read a file; real power-cycle persistence, bootloader installation, account management, Secure Boot, automatic rollback and hardware installation remain unfinished.

## Requirements before a real installable release

An isolated disk installer must create a GPT, EFI System Partition and ext4/Btrfs roots; install a verified kernel, initramfs and bootloader; configure fstab and accounts; build a recovery option; and pass UEFI and BIOS boot tests on disposable VM disks before any physical-drive support is added.
