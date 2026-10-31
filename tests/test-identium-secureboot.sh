#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n identium/secureboot.sh
python3 - <<'PY'
import json
with open("identium/distribution.json", encoding="utf-8") as f:
    state=json.load(f)
assert state["name"] == "IDENTIUM"
assert state["secure_boot"]["efi_image_production"] is False
assert state["secure_boot"]["trusted_boot_chain_verified"] is False
PY
if grep -Eiq 'mokutil[[:space:]]+--import|efi-updatevar|efibootmgr[[:space:]]+(-c|--create)' identium/secureboot.sh; then
 echo 'Unexpected firmware/key enrollment operation' >&2; exit 1
fi
echo 'PASS: IDENTIUM Secure Boot preparation is non-enrolling'
