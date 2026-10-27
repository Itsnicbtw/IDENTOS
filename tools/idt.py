#!/usr/bin/env python3
"""IDENT .idt v1: verified Python app bundles. Not Windows .exe compatibility."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import zipfile

MAX_PAYLOAD = 8 * 1024 * 1024
MAX_MANIFEST = 32 * 1024

def validated(bundle):
    if bundle.suffix.lower() != ".idt":
        raise ValueError("Only .idt bundles are accepted")
    with zipfile.ZipFile(bundle) as z:
        names = z.namelist()
        if len(names) != 2 or len(set(names)) != 2 or "manifest.json" not in names:
            raise ValueError("Bundle must contain exactly manifest.json and one payload")
        manifest_file = z.getinfo("manifest.json")
        if manifest_file.file_size > MAX_MANIFEST:
            raise ValueError("Manifest exceeds size limit")
        m = json.loads(z.read("manifest.json"))
        if not isinstance(m, dict) or m.get("format") != "ident.idt/1":
            raise ValueError("Unsupported package format")
        if not isinstance(m.get("name"), str) or not 1 <= len(m["name"]) <= 100:
            raise ValueError("Invalid app name")
        if m.get("runtime") != "python3":
            raise ValueError("Only the python3 runtime is currently supported")
        payload = m.get("entrypoint")
        if not isinstance(payload, str) or not payload.endswith(".py") or "/" in payload or "\\\\" in payload or payload.startswith("."):
            raise ValueError("Invalid entrypoint")
        if set(names) != {"manifest.json", payload}:
            raise ValueError("Unexpected bundle contents")
        info = z.getinfo(payload)
        if info.file_size > MAX_PAYLOAD or info.file_size == 0:
            raise ValueError("Payload size invalid")
        if (info.external_attr >> 16) & 0o170000 == 0o120000:
            raise ValueError("Symlinks are forbidden")
        data = z.read(payload)
        digest = m.get("sha256")
        if not isinstance(digest, str) or hashlib.sha256(data).hexdigest() != digest:
            raise ValueError("SHA-256 mismatch")
        return m, data

def main():
    parser = argparse.ArgumentParser(description="IDENT OS .idt package inspector / runner")
    parser.add_argument("package", type=Path)
    parser.add_argument("--run", action="store_true", help="Execute reviewed payload as current user")
    args = parser.parse_args()
    try:
        manifest, data = validated(args.package)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile, json.JSONDecodeError, RuntimeError) as exc:
        print(f"Invalid IDT: {exc}", file=sys.stderr)
        return 2
    print(f"IDENT app: {manifest['name']} ({manifest['format']})")
    print(f"Runtime: {manifest['runtime']} | checksum verified")
    if not args.run:
        print("Inspect-only. Use --run to execute untrusted code at your own risk.")
        return 0
    # This is not a sandbox. Do not run unfamiliar packages.
    with tempfile.TemporaryDirectory(prefix="identos-idt-") as directory:
        target = Path(directory) / "application.py"
        target.write_bytes(data)
        os.chmod(target, 0o600)
        result = subprocess.run([sys.executable, "-I", str(target)], check=False, cwd=directory)
        return result.returncode

if __name__ == "__main__":
    sys.exit(main())
