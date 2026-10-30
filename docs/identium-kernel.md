# IDENTIUM kernel track

IDENTIUM begins with an **IDENT-maintained Linux kernel**: an upstream Linux source tree, an IDENTIUM config overlay, an isolated build directory, version metadata and kernel artifact hashing. This is not an original from-scratch kernel.

## Build

Install the Linux kernel compilation prerequisites (C compiler, make, bc, bison, flex, libssl development files, libelf development files and associated build dependencies). Obtain a trusted upstream Linux kernel source archive, authenticate its release/signature from the kernel publisher and extract it in a separate directory.

```sh
IDENTIUM_KERNEL_SOURCE=/path/to/verified/linux-source \
IDENTIUM_KERNEL_OUTPUT="$PWD/build/identium-kernel" \
IDENTIUM_KERNEL_JOBS=4 bash kernel/build-identium.sh
```

The expected output is `build/identium-kernel/arch/x86/boot/bzImage`, with a checksum and version record. The builder **does not install the kernel on the host**.

## Scope and acceptance gates

The overlay requests initrd, EFI, ext4, virtio drivers and hardening settings. A requested config symbol can be disabled by upstream dependencies or changes; inspect the final `.config` before claiming support.

Next: connect the built kernel to the separate IDENTIUM minimal initramfs and run an isolated QEMU serial-boot test. Then compile and package matching modules, establish a signed boot chain, test persistent-disk boot, and verify real hardware. Neither Secure Boot nor independent rootfs readiness follows automatically from compiling `bzImage`.

Do not replace the currently bootable Debian-based kernel until these gates pass.
