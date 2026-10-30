#!/usr/bin/env python3
"""Verify immutable inputs and publish a boot-bundle integrity manifest."""
import argparse
import hashlib
import json
from pathlib import Path

def sha(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--kernel", type=Path, required=True)
    p.add_argument("--initrd", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    for item in (a.kernel, a.initrd):
        if item.is_symlink() or not item.is_file() or item.stat().st_size == 0:
            p.error("Inputs must be nonempty, regular, non-symlink files")
    if a.output.exists() or a.output.is_symlink():
        p.error("Will not replace existing manifest")
    a.output.parent.mkdir(parents=True, exist_ok=True)
    data = {"schema": 1, "firmware_trust_verified": False,
            "physical_boot_verified": False, "installed_disk_boot_verified": False,
            "items": {key: {"name": path.name, "bytes": path.stat().st_size, "sha256": sha(path)}
                      for key, path in (("kernel", a.kernel), ("initrd", a.initrd))}}
    a.output.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    print("Bundle inputs hashed; no boot or Secure Boot claim.")

if __name__ == "__main__":
    main()
