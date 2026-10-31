#!/usr/bin/env python3
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
class KernelTests(unittest.TestCase):
    def test_shell(self):
        subprocess.run(["bash", "-n", str(ROOT/"kernel/build-identium.sh")], check=True)
    def test_config(self):
        lines = (ROOT/"kernel/config/identium-x86_64.fragment").read_text().splitlines()
        entries = [line.split("=", 1)[0] for line in lines if line.startswith("CONFIG_")]
        self.assertEqual(len(entries), len(set(entries)))
        self.assertIn('CONFIG_LOCALVERSION="-identium"', lines)
        self.assertIn("CONFIG_BLK_DEV_INITRD=y", lines)
    def test_requires_kernel_source(self):
        result = subprocess.run(["bash", str(ROOT/"kernel/build-identium.sh")], env={"PATH":"/usr/bin:/bin"}, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
if __name__ == "__main__":
    unittest.main()
