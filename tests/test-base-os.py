#!/usr/bin/env python3
"""Static base system invariants; no privileged or destructive operations."""
import configparser
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
BASE = ROOT / "base-os"


class BaseOSChecks(unittest.TestCase):
    def test_shell_syntax(self):
        subprocess.run(["sh", "-n", str(BASE / "identos-base-check")], check=True)

    def test_service_is_oneshot_and_read_only(self):
        service = (BASE / "identos-base-check.service").read_text()
        self.assertIn("Type=oneshot", service)
        self.assertIn("ProtectSystem=strict", service)
        self.assertIn("NoNewPrivileges=yes", service)
        self.assertIn("ExecStart=/usr/local/bin/identos-base-check", service)
        self.assertNotIn("User=root\nExecStart=/bin/sh -c", service)

    def test_tmpfiles_runtime_only(self):
        lines = [x.strip() for x in (BASE / "identos-base.tmpfiles").read_text().splitlines()
                 if x.strip() and not x.startswith("#")]
        self.assertEqual(lines, ["d /run/identos 0755 root root -"])

    def test_sysctl_keys_are_allowlisted(self):
        parsed = {}
        for line in (BASE / "identos-base.sysctl").read_text().splitlines():
            if line.strip() and not line.startswith("#"):
                key, value = [x.strip() for x in line.split("=", 1)]
                parsed[key] = value
        self.assertEqual(parsed, {
            "fs.protected_symlinks": "1",
            "fs.protected_hardlinks": "1",
            "fs.protected_fifos": "2",
            "fs.protected_regular": "2",
        })


if __name__ == "__main__":
    unittest.main()
