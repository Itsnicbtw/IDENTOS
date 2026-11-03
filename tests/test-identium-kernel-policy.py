#!/usr/bin/env python3
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "kernel"))
from importlib.machinery import SourceFileLoader
module = SourceFileLoader("verify_config", str(ROOT / "kernel/verify-config.py")).load_module()

class KernelPolicyTests(unittest.TestCase):
    def test_empty_config_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            f = pathlib.Path(d) / ".config"
            f.write_text("")
            self.assertNotEqual(module.main.__name__, "")
            proc = subprocess.run([sys.executable, str(ROOT / "kernel/verify-config.py"), str(f)], capture_output=True)
            self.assertNotEqual(proc.returncode, 0)
    def test_required_contract(self):
        with tempfile.TemporaryDirectory() as d:
            f = pathlib.Path(d) / ".config"
            f.write_text("".join(f"{k}={v}\n" for k, v in module.REQUIRED.items()))
            proc = subprocess.run([sys.executable, str(ROOT / "kernel/verify-config.py"), str(f)], capture_output=True)
            self.assertEqual(proc.returncode, 0, proc.stderr.decode())
    def test_hardware_profile_includes_storage(self):
        t = (ROOT / "kernel/config/identium-hardware-extended.fragment").read_text()
        self.assertIn("CONFIG_BTRFS_FS=y", t)
        self.assertIn("CONFIG_VFAT_FS=y", t)

if __name__ == "__main__":
    unittest.main()
