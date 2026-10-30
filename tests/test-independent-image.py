#!/usr/bin/env python3
import io
import pathlib
import subprocess
import sys
import tarfile
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class ImageSafetyTests(unittest.TestCase):
    def validate(self, archive):
        return subprocess.run([sys.executable, str(ROOT / "independent/validate-rootfs.py"), str(archive)],
                              capture_output=True)

    def test_reject_parent_traversal(self):
        with tempfile.TemporaryDirectory() as folder:
            archive = pathlib.Path(folder) / "root.tar.gz"
            with tarfile.open(archive, "w:gz") as handle:
                info = tarfile.TarInfo("../outside")
                data = b"unsafe"
                info.size = len(data)
                handle.addfile(info, io.BytesIO(data))
            self.assertNotEqual(self.validate(archive).returncode, 0)

    def test_accept_simple_root(self):
        with tempfile.TemporaryDirectory() as folder:
            archive = pathlib.Path(folder) / "root.tar.gz"
            with tarfile.open(archive, "w:gz") as handle:
                info = tarfile.TarInfo("etc/hostname")
                data = b"identos\n"
                info.size = len(data)
                handle.addfile(info, io.BytesIO(data))
            self.assertEqual(self.validate(archive).returncode, 0)

if __name__ == "__main__":
    unittest.main()
