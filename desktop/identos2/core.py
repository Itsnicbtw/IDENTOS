"""IDENT Desktop 2: command policy and settings, independent from the UI."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path

DEFAULTS = {"clock_24h": True, "panel_height": 48}
COMMANDS = {
    "terminal": ("xterm",),
    "files": ("pcmanfm",),
    "browser": ("identos-browser",),
    "applications": ("rofi", "-show", "drun"),
    "windows": ("rofi", "-show", "window"),
    "diagnostics": ("xterm", "-e", "identos-graphics-check"),
}
VALID = frozenset(DEFAULTS)


def settings_path(home: Path | None = None) -> Path:
    base = Path(os.environ.get("XDG_CONFIG_HOME") or (home or Path.home()) / ".config")
    return base / "identos" / "desktop2.json"


def load_settings(path: Path | None = None) -> dict:
    settings = DEFAULTS.copy()
    target = path or settings_path()
    try:
        data = json.loads(target.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            for key, value in data.items():
                if key in VALID and isinstance(value, type(DEFAULTS[key])):
                    if key != "panel_height" or 36 <= value <= 96:
                        settings[key] = value
    except (OSError, ValueError, UnicodeError):
        pass
    return settings


def save_settings(data: dict, path: Path | None = None) -> None:
    target = path or settings_path()
    cleaned = {key: value for key, value in data.items() if key in VALID
               and isinstance(value, type(DEFAULTS[key]))}
    if "panel_height" in cleaned and not 36 <= cleaned["panel_height"] <= 96:
        raise ValueError("Panel height must be 36..96")
    target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = target.with_name(target.name + ".tmp")
    try:
        with temporary.open("w", encoding="utf-8") as output:
            json.dump(cleaned, output, sort_keys=True)
            output.write("\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)


def launch(action: str) -> bool:
    """Launch only registered actions. Never invoke a shell for an action."""
    argv = COMMANDS.get(action)
    if argv is None:
        return False
    if shutil.which(argv[0]) is None:
        return False
    try:
        subprocess.Popen(argv, start_new_session=True, close_fds=True)
        return True
    except OSError:
        return False
