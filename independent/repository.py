#!/usr/bin/env python3
"""Offline repository manifest tooling. No package installation or network access."""
import argparse
import hashlib
import json
import pathlib
import subprocess

def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1048576), b""):
            h.update(chunk)
    return h.hexdigest()

def index(directory):
    files = []
    for file in sorted(directory.iterdir()):
        if file.is_symlink():
            raise ValueError("Symlink not allowed")
        if file.is_file() and file.name.endswith(".idt"):
            files.append({"name": file.name, "bytes": file.stat().st_size, "sha256": digest(file)})
    return {"schema": 1, "packages": files}

def verify(directory, manifest, signature, public_key):
    subprocess.run(["openssl", "dgst", "-sha256", "-verify", str(public_key),
                    "-signature", str(signature), str(manifest)], check=True,
                   stdout=subprocess.DEVNULL)
    expected = json.loads(manifest.read_text(encoding="utf-8"))
    if expected != index(directory):
        raise ValueError("Package metadata mismatch")
    return True

def main():
    p = argparse.ArgumentParser()
    p.add_argument("action", choices=("index", "verify"))
    p.add_argument("--packages", type=pathlib.Path, required=True)
    p.add_argument("--manifest", type=pathlib.Path, required=True)
    p.add_argument("--signature", type=pathlib.Path)
    p.add_argument("--public-key", type=pathlib.Path)
    a = p.parse_args()
    if not a.packages.is_dir() or a.packages.is_symlink():
        p.error("Packages must be a directory, not a symlink")
    if a.action == "index":
        if a.manifest.exists():
            p.error("Refusing to replace existing manifest")
        a.manifest.write_text(json.dumps(index(a.packages), sort_keys=True, indent=2) + "\n")
        print("Unsigned index created. Sign externally with a protected private key.")
    else:
        if not a.signature or not a.public_key:
            p.error("Verification requires signature and public key")
        verify(a.packages, a.manifest, a.signature, a.public_key)
        print("PASS: signed manifest and package contents match")

if __name__ == "__main__":
    main()
