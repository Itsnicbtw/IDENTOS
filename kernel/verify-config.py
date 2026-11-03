#!/usr/bin/env python3
"""Fail build if essential IDENTIUM kernel features were silently dropped."""
import argparse
import pathlib
import sys

REQUIRED = {
    "CONFIG_BLK_DEV_INITRD": "y",
    "CONFIG_DEVTMPFS": "y",
    "CONFIG_EXT4_FS": "y",
    "CONFIG_EFI": "y",
    "CONFIG_EFI_STUB": "y",
    "CONFIG_VIRTIO_PCI": "y",
    "CONFIG_VIRTIO_BLK": "y",
    "CONFIG_USB_STORAGE": "y",
    "CONFIG_BLK_DEV_NVME": "y",
    "CONFIG_SATA_AHCI": "y",
    "CONFIG_RANDOMIZE_BASE": "y",
    "CONFIG_STACKPROTECTOR_STRONG": "y",
    "CONFIG_STRICT_KERNEL_RWX": "y",
}
def read_config(path):
    result = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("CONFIG_") and "=" in line:
            key, value = line.split("=", 1)
            result[key] = value
        elif line.startswith("# CONFIG_") and line.endswith(" is not set"):
            result[line[2:].split(" ", 1)[0]] = "n"
    return result
def main():
    p = argparse.ArgumentParser()
    p.add_argument("config", type=pathlib.Path)
    args = p.parse_args()
    current = read_config(args.config)
    bad = {k: {"expected": v, "actual": current.get(k, "absent")}
           for k, v in REQUIRED.items() if current.get(k) != v}
    if bad:
        for k, values in bad.items():
            print(f"FAIL {k}: expected {values['expected']}, got {values['actual']}", file=sys.stderr)
        return 1
    print(f"PASS: {len(REQUIRED)} mandatory kernel configuration settings")
    return 0
if __name__ == "__main__":
    sys.exit(main())
