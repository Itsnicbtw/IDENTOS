#!/usr/bin/env python3
"""Create or verify a machine-readable SHA256 release manifest, no network access."""
import argparse
import hashlib
import json
from pathlib import Path

def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--iso", required=True)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    image = Path(args.iso)
    manifest = Path(args.manifest)
    if not image.is_file() or image.is_symlink():
        parser.error("ISO must be a regular, non-symlink file")
    if args.verify:
        data = json.loads(manifest.read_text(encoding="utf-8"))
        ok = (data.get("schema") == 1 and data.get("artifact") == image.name
              and data.get("bytes") == image.stat().st_size
              and data.get("sha256") == sha256(image))
        print("PASS: release manifest verified" if ok else "FAIL: release manifest mismatch")
        raise SystemExit(0 if ok else 1)
    data = {"schema": 1, "artifact": image.name, "bytes": image.stat().st_size,
            "sha256": sha256(image), "base_distribution": "Debian Trixie",
            "architecture": "amd64"}
    manifest.write_text(json.dumps(data, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print("Wrote", manifest)

if __name__ == "__main__":
    main()
