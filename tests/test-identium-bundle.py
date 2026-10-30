#!/usr/bin/env python3
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "kernel/verify-boot-bundle.py"
class TestBundle(unittest.TestCase):
    def test_manifest_and_no_overwrite(self):
        with tempfile.TemporaryDirectory() as folder:
            directory = pathlib.Path(folder)
            kernel, initrd, out = (directory/x for x in ("bzImage", "initrd.gz", "bundle.json"))
            kernel.write_bytes(b"kernel")
            initrd.write_bytes(b"initrd")
            cmd = [sys.executable, str(SCRIPT), "--kernel", str(kernel), "--initrd", str(initrd), "--output", str(out)]
            subprocess.run(cmd, check=True)
            data = json.loads(out.read_text())
            self.assertFalse(data["physical_boot_verified"])
            self.assertEqual(data["items"]["kernel"]["bytes"], 6)
            self.assertNotEqual(subprocess.run(cmd, capture_output=True).returncode, 0)
if __name__ == "__main__":
    unittest.main()
