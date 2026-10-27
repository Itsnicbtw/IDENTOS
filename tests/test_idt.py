#!/usr/bin/env python3
"""Test .idt packaging and execution without external dependencies."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import zipfile

runner = Path(__file__).resolve().parent.parent / "tools" / "idt.py"
with tempfile.TemporaryDirectory() as td:
    root = Path(td)
    program = b'print("HELLO_FROM_IDT")\n'
    manifest = {"format": "ident.idt/1", "name": "Test application", "runtime": "python3", "entrypoint": "main.py", "sha256": hashlib.sha256(program).hexdigest()}
    package = root / "test.idt"
    def pack(info):
        with zipfile.ZipFile(package, "w") as z:
            z.writestr("manifest.json", json.dumps(info))
            z.writestr("main.py", program)
    pack(manifest)
    inspect = subprocess.run([sys.executable, str(runner), str(package)], capture_output=True, text=True)
    assert inspect.returncode == 0 and "checksum verified" in inspect.stdout, inspect.stderr
    assert "HELLO_FROM_IDT" not in inspect.stdout
    launch = subprocess.run([sys.executable, str(runner), str(package), "--run"], capture_output=True, text=True)
    assert launch.returncode == 0 and "HELLO_FROM_IDT" in launch.stdout, launch.stderr
    pack({**manifest, "sha256": "0" * 64})
    corrupted = subprocess.run([sys.executable, str(runner), str(package)], capture_output=True, text=True)
    assert corrupted.returncode != 0 and "mismatch" in corrupted.stderr
    pack({**manifest, "entrypoint": "../main.py"})
    traversal = subprocess.run([sys.executable, str(runner), str(package)], capture_output=True, text=True)
    assert traversal.returncode != 0
    print("PASS: .idt inspection, explicit execution and integrity/path rejection")
