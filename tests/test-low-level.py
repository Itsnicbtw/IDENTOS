#!/usr/bin/env python3
"""Fast local tests, no VM or root privileges required."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as temporary:
    work = Path(temporary)
    (work / "proc").mkdir()
    (work / "proc/cpuinfo").write_text("flags : fpu vmx sse2\n")
    (work / "proc/meminfo").write_text("MemTotal: 8192 kB\n")
    (work / "sys/firmware/efi").mkdir(parents=True)
    (work / "sys/fs/cgroup").mkdir(parents=True)
    (work / "sys/fs/cgroup/cgroup.controllers").write_text("cpu memory")
    probe = subprocess.run([sys.executable, str(root / "system/identos-capabilities.py"),
                            "--root", str(work)], capture_output=True, text=True, check=True)
    result = json.loads(probe.stdout)
    assert result["uefi"] and result["virtualization_cpu_flag"] and result["cgroup_v2"]
    assert result["memory_total_kib"] == 8192 and not result["tpm_device"]
    image = work / "sample.iso"
    image.write_bytes(b"IDENT OS test artifact")
    manifest = work / "manifest.json"
    cmd = [sys.executable, str(root / "scripts/identos-release-manifest.py"),
           "--iso", str(image), "--manifest", str(manifest)]
    subprocess.run(cmd, check=True)
    subprocess.run(cmd + ["--verify"], check=True)
    image.write_bytes(b"modified")
    bad = subprocess.run(cmd + ["--verify"], capture_output=True)
    assert bad.returncode != 0, "A modified artifact must not verify"
print("PASS: capabilities fixture and manifest integrity tests")
