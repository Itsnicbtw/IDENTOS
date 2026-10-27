# Boot IDENT OS as a graphical operating system

The **live desktop** is a Debian 13 + XFCE-based IDENT OS prototype. It boots from an ISO and does not replace the computer's existing OS. Boot it in a VM before attempting real hardware.

## 1. Get the ISO without building on your computer

In the [IDENT OS Actions page](https://github.com/Itsnicbtw/IDENTOS/actions/workflows/live-desktop.yml), select a **successful** main-branch run. Download the `identos-live-amd64` artifact and extract both:

- `identos-live-amd64.iso`
- `identos-live-amd64.sha256`

Artifacts expire after the configured retention period. You can also use GitHub CLI:

```bash
mkdir -p build
gh run list -R Itsnicbtw/IDENTOS --workflow live-desktop.yml --branch main --status success
gh run download RUN_ID -R Itsnicbtw/IDENTOS -n identos-live-amd64 -D build
(cd build && sha256sum -c identos-live-amd64.sha256)
```

Replace `RUN_ID` with the successful build's ID. A build from a different branch may contain unmerged changes.

## 2. Boot on Linux with a graphical QEMU window

Install QEMU and optional UEFI firmware:

```bash
sudo apt-get install qemu-system-x86 ovmf
bash scripts/boot-live-vm.sh
```

Defaults to a BIOS-style boot with 4 GiB RAM and two virtual CPUs. For UEFI:

```bash
bash scripts/boot-live-vm.sh --uefi
```

QEMU's graphical window should show the ISO boot menu, boot progress and eventually the LightDM/XFCE desktop. **This graphical login has not yet been automatically proven by CI**; verify it manually.

On a Chromebook, QEMU inside Crostini may lack KVM and graphical performance may be slow. Downloading or running this ISO can consume multiple gigabytes of local storage. Use another capable machine or remote VM where appropriate.

## 3. Optional persistent home directory in a disposable VM

```bash
bash scripts/create-persistence-image.sh build/home-persistence.img 2048
bash scripts/boot-live-vm.sh --persist build/home-persistence.img
```

The helper only creates a new image file, not partitions on a real disk. At boot, live-boot can discover the filesystem labelled `persistence` and its `/persistence.conf` containing `/home union`. Create a test file in the live user's home and reboot the VM. Confirm it survives. Some boot menu entries may require explicitly enabling persistence.

Only the configured home directory is persistent; this is **not** a full installation or persistent root operating system. Keep important data backed up.

## 4. Test checklist

1. The ISO checksum verifies.
2. BIOS and UEFI boot menus appear in QEMU.
3. The kernel reaches the live userspace.
4. LightDM launches and XFCE accepts mouse and keyboard input.
5. Browser, terminal, file manager and `identos-doctor` open.
6. Networking works in QEMU.
7. With the optional persistence image attached, files survive a guest reboot.

**Current release gate:** automatic CI proves image construction and checksum, not all seven tests. Do not advertise fully verified installability or compatibility on arbitrary hardware.

## Real hardware

Do **not** write the prototype to your main SSD or change firmware settings just to test it. A supported USB boot and a non-destructive installer need separate hardware validation. This milestone is a graphical virtual-machine boot path.
