# IDENT application format (.idt), draft v1

An `.idt` file is a ZIP container, **not** a Windows PE executable and **not** a new CPU instruction format. The file extension is IDENT OS's app-distribution format.

Version 1 contains precisely two entries:

- `manifest.json`, with `format`, `name`, `runtime`, `entrypoint` and `sha256`
- `main.py`, the Python entrypoint referenced by the manifest

Example manifest:

```json
{
  "format": "ident.idt/1",
  "name": "Hello IDENT",
  "runtime": "python3",
  "entrypoint": "main.py",
  "sha256": "<64-character lowercase SHA-256 of main.py>"
}
```

Build with Python's `zipfile`, including a real hash of the Python payload. Inspect with:

```bash
python3 tools/idt.py hello.idt
```

Only execute code you trust:

```bash
python3 tools/idt.py hello.idt --run
```

**Security limits:** SHA-256 detects corruption or tampering relative to the manifest but does not authenticate a publisher: a malicious actor can change both payload and hash. This version deliberately does not autoexecute, install system-wide, gain root privileges or claim to sandbox programs. Executing an unknown .idt is unsafe. Future phases need signatures, declared permissions, a sandbox and an app installer before default double-click execution.
