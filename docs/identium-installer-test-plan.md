# VM installer acceptance tests (unfinished)

The first release gate is a fully disposable image. Never run the installer on /dev/sdX, /dev/nvmeXnY, mapped host partitions or removable disks.

1. Build an IDENTIUM kernel and independent initrd from the same source revision.
2. Run `independent/install-vm-image.sh` to create a new raw .img file, including the GPT, ESP, ext4 root and EFI bootloader.
3. Inspect with `guestfish --ro -a image.img run : list-partitions`, and confirm EFI loader exists on ESP and IDENTROOT partition has the correct label.
4. Boot with a **copy** of OVMF firmware in a disposable QEMU VM and ensure the serial output includes the IDENTIUM PID 1 banner and `persistent storage available at /persist`.
5. Write a unique marker to `/persist`, shut down, reboot with the same image, and confirm the marker survives.
6. Validate Secure Boot denial on an unsigned loader; do not enrol release keys for experiments.
7. Add authenticated accounts, installer UX, rescue boot, rollback, update provenance, and repeated power-loss tests before any physical installation support.

Only the code and static safety checks are currently committed. Actual VM boot, reboot, persistence and Wine application compatibility remain unverified.
