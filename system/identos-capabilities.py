#!/usr/bin/env python3
"""Read-only platform capability report for IDENT OS. No hardware probing writes."""
import argparse
import json
import os
import platform
from pathlib import Path

def read(path, limit=1024):
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace")[:limit].strip()
    except (OSError, UnicodeError):
        return None

def capabilities(root=Path("/")):
    prefix = Path(root)
    def exists(path):
        return (prefix / path.lstrip("/")).exists()
    cpu = read(prefix / "proc/cpuinfo", 65536) or ""
    return {
        "schema": 1,
        "architecture": platform.machine(),
        "kernel": platform.release() if prefix == Path("/") else "fixture",
        "uefi": exists("/sys/firmware/efi"),
        "virtualization_cpu_flag": any(flag in cpu.split() for flag in ("vmx", "svm")),
        "kvm_device": exists("/dev/kvm"),
        "tpm_device": exists("/dev/tpm0") or exists("/dev/tpmrm0"),
        "drm_graphics": exists("/sys/class/drm"),
        "battery": exists("/sys/class/power_supply") and any((prefix / "sys/class/power_supply").glob("BAT*")),
        "cgroup_v2": exists("/sys/fs/cgroup/cgroup.controllers"),
        "memory_total_kib": next((int(row.split()[1]) for row in (read(prefix / "proc/meminfo") or "").splitlines() if row.startswith("MemTotal:")), None),
    }

def main():
    parser = argparse.ArgumentParser(description="IDENT OS local read-only capability report")
    parser.add_argument("--root", default="/", help=argparse.SUPPRESS)
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args()
    print(json.dumps(capabilities(Path(args.root)), indent=2 if args.pretty else None, sort_keys=True))

if __name__ == "__main__":
    main()
