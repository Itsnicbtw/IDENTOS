#!/usr/bin/env python3
import importlib.util
import json
import pathlib
import subprocess
import sys
import unittest
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[1]

class BootManagementTests(unittest.TestCase):
    def test_manifest_is_explicit_about_base(self):
        data = json.loads((ROOT / "base-os/identos-distribution.json").read_text())
        self.assertEqual(data["base"]["codename"], "trixie")
        self.assertFalse(data["independent_rootfs"])
        self.assertFalse(data["independent_package_repository"])

    def test_cli_help(self):
        subprocess.run([sys.executable, str(ROOT / "base-os/identos-bootctl"), "--help"],
                       capture_output=True, check=True)

    def test_inspector_no_mutation(self):
        spec = importlib.util.spec_from_file_location("bootinspect", ROOT / "base-os/identos-bootctl")
        from importlib.machinery import SourceFileLoader
        module = SourceFileLoader("bootinspect", str(ROOT / "base-os/identos-bootctl")).load_module()
        with patch.object(module.shutil, "which", return_value=None):
            data = module.inspect()
        self.assertEqual(data["schema"], 1)
        self.assertIsNone(data["default_target"])

if __name__ == "__main__":
    unittest.main()
