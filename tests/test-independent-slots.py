#!/usr/bin/env python3
import importlib.machinery
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
slot = importlib.machinery.SourceFileLoader("ident_slots", str(ROOT / "independent/slot-manager.py")).load_module()

class SlotTests(unittest.TestCase):
    def test_successful_update(self):
        initial = slot.DEFAULT.copy()
        staged = slot.change(initial, "stage", "B")
        running = slot.change(staged, "boot-attempt")
        self.assertEqual(running["active"], "B")
        self.assertEqual(slot.change(running, "confirm")["last_good"], "B")

    def test_three_failures_return_to_last_good(self):
        state = slot.change(slot.DEFAULT.copy(), "stage", "B")
        for _ in range(3):
            state = slot.change(state, "boot-attempt")
        self.assertEqual(state["active"], "A")
        self.assertIsNone(state["pending"])

    def test_no_staging_active_slot(self):
        with self.assertRaises(ValueError):
            slot.change(slot.DEFAULT.copy(), "stage", "A")

if __name__ == "__main__":
    unittest.main()
