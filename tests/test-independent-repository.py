#!/usr/bin/env python3
import importlib.machinery
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
repo = importlib.machinery.SourceFileLoader("ident_repo", str(ROOT / "independent/repository.py")).load_module()

class IndexTests(unittest.TestCase):
    def test_index_and_detect_change(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory)
            package = path / "hello.idt"
            package.write_bytes(b"test package")
            first = repo.index(path)
            self.assertEqual(first["schema"], 1)
            self.assertEqual(first["packages"][0]["name"], "hello.idt")
            package.write_bytes(b"changed")
            self.assertNotEqual(first, repo.index(path))

    def test_reject_symlink(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory)
            (path / "package.idt").symlink_to("/dev/null")
            with self.assertRaises(ValueError):
                repo.index(path)

if __name__ == "__main__":
    unittest.main()
