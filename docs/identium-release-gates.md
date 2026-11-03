# IDENTIUM kernel product gates

The kernel build has a generic x86-64 baseline, extended storage/network/hardware policy, security-oriented configuration and post-configuration enforcement of hard requirements. Source remains upstream Linux, with IDENTIUM project patches/configuration. A broad option list does **not** guarantee every peripheral is supported: firmware, GPU, Wi-Fi chipsets and platform-specific drivers must be tested.

## Mandatory before an installable release

1. Confirm upstream kernel tarball authenticity using trusted publisher signatures and pinned release versions. Never promote the experimental unauthenticated download workflow as a release pipeline.
2. Build reproducibly in clean CI and publish provenance and hashes.
3. Boot the exact IDENTIUM kernel with the independent rootfs, then verify ext4 disk mount, persist changes and reboot on disposable GPT/EFI virtual disks.
4. Provide authenticated accounts, least-privilege services, verified package updates and tested full recovery.
5. Establish signed bootloader/kernel/initrd chain, firmware trust tests and Secure Boot negative/tamper tests.
6. Pass BIOS, UEFI, hardware smoke tests and accessibility usability review.

The product label remains **experimental developer preview** until those requirements pass.
