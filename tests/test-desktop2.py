#!/usr/bin/env python3
"""Headless tests for desktop policy; no X server required."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "desktop"))
from identos2 import core


class DesktopCoreTests(unittest.TestCase):
    def test_settings_defaults_and_filtering(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / "settings.json"
            self.assertEqual(core.load_settings(file), core.DEFAULTS)
            file.write_text(json.dumps({"panel_height": 22, "clock_24h": False, "unknown": 4}))
            self.assertEqual(core.load_settings(file), {"clock_24h": False, "panel_height": 48})

    def test_atomic_settings_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "config" / "settings.json"
            core.save_settings({"panel_height": 52, "clock_24h": True, "extra": "ignored"}, target)
            self.assertEqual(core.load_settings(target)["panel_height"], 52)
            self.assertNotIn("extra", json.loads(target.read_text()))
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)

    def test_reject_invalid_height(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                core.save_settings({"panel_height": 500}, Path(directory) / "config.json")

    @patch("identos2.core.subprocess.Popen")
    @patch("identos2.core.shutil.which", return_value="/usr/bin/xterm")
    def test_allowlisted_launch(self, _, popen):
        self.assertFalse(core.launch("untrusted; rm -rf /"))
        self.assertTrue(core.launch("terminal"))
        popen.assert_called_once_with(("xterm",), start_new_session=True, close_fds=True)


if __name__ == "__main__":
    unittest.main()
