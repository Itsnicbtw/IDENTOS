#!/usr/bin/env python3
"""Reject unsafe tar entries before local VM image extraction."""
import pathlib
import sys
import tarfile

def validate(filename):
    with tarfile.open(filename, "r:gz") as archive:
        members = archive.getmembers()
        if len(members) > 100000:
            raise ValueError("Too many archive entries")
        total = 0
        for member in members:
            name = pathlib.PurePosixPath(member.name)
            if name.is_absolute() or ".." in name.parts:
                raise ValueError("Unsafe archive path")
            if not (member.isfile() or member.isdir()):
                # Symlinks are required by typical rootfs layouts. Reject them for
                # image installer until link-safe staging is implemented.
                raise ValueError("Links and special files unsupported by installer")
            total += member.size
            if total > 8 * 1024**3:
                raise ValueError("Archive contents too large")

if __name__ == "__main__":
    try:
        validate(sys.argv[1])
    except (OSError, ValueError, tarfile.TarError, IndexError) as error:
        print(f"REJECTED: {error}", file=sys.stderr)
        sys.exit(1)
    print("PASS: safe archive members")
