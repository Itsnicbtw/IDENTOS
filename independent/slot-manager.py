#!/usr/bin/env python3
"""File-backed A/B slot state machine for offline update simulation.

Never edits partitions, firmware, bootloader entries or device files.
"""
import argparse
import json
import os
from pathlib import Path

DEFAULT = {"schema": 1, "active": "A", "last_good": "A", "pending": None, "tries_remaining": 0}
SLOTS = ("A", "B")

def validate(s):
    if (not isinstance(s, dict) or s.get("schema") != 1 or
        s.get("active") not in SLOTS or s.get("last_good") not in SLOTS or
        s.get("pending") not in (*SLOTS, None) or
        not isinstance(s.get("tries_remaining"), int) or
        not 0 <= s["tries_remaining"] <= 3):
        raise ValueError("Invalid slot state")
    return s

def change(state, action, slot=None):
    s = validate(state.copy())
    if action == "stage":
        if slot not in SLOTS or slot == s["active"] or s["pending"] is not None:
            raise ValueError("Stage requires inactive slot and no pending update")
        s["pending"], s["tries_remaining"] = slot, 3
    elif action == "boot-attempt":
        if s["pending"] is not None:
            s["tries_remaining"] -= 1
            if s["tries_remaining"] <= 0:
                s["pending"], s["active"], s["tries_remaining"] = None, s["last_good"], 0
            else:
                s["active"] = s["pending"]
    elif action == "confirm":
        if s["pending"] is None or s["active"] != s["pending"]:
            raise ValueError("No pending boot to confirm")
        s["last_good"], s["pending"], s["tries_remaining"] = s["active"], None, 0
    elif action == "rollback":
        s["active"], s["pending"], s["tries_remaining"] = s["last_good"], None, 0
    else:
        raise ValueError("Unknown operation")
    return s

def main():
    parser = argparse.ArgumentParser(description="Simulate IDENT A/B rootfs update transitions")
    parser.add_argument("--state", required=True, help="Regular JSON file, never a device")
    parser.add_argument("action", choices=("init", "stage", "boot-attempt", "confirm", "rollback", "show"))
    parser.add_argument("--slot", choices=SLOTS)
    args = parser.parse_args()
    path = Path(args.state)
    if str(path).startswith(("/dev/", "/proc/", "/sys/")) or path.is_symlink():
        parser.error("State must be an ordinary file")
    if path.exists() and not path.is_file():
        parser.error("State must be a regular file")
    if args.action == "init":
        if path.exists():
            parser.error("Refusing existing state file")
        state = DEFAULT.copy()
    else:
        state = validate(json.loads(path.read_text(encoding="utf-8")))
        if args.action != "show":
            state = change(state, args.action, args.slot)
    if args.action != "show":
        tmp = path.with_name(path.name + ".tmp")
        if tmp.exists() or tmp.is_symlink():
            parser.error("Temporary file already exists")
        try:
            fd = os.open(tmp, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            with os.fdopen(fd, "w") as file:
                json.dump(state, file, sort_keys=True)
                file.write("\n")
                file.flush()
                os.fsync(file.fileno())
            os.replace(tmp, path)
        finally:
            tmp.unlink(missing_ok=True)
    print(json.dumps(state, sort_keys=True))

if __name__ == "__main__":
    main()
