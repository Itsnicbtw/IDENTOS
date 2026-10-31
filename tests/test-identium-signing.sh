#!/usr/bin/env bash
# Test signing with disposable CI keys. NEVER use release keys in CI.
set -euo pipefail
cd "$(dirname "$0")/.."
for tool in openssl sbsign sbverify objcopy cc; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 2; }; done
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# Compile a tiny PE/COFF EFI binary with a cross-compiler provided by CI.
command -v x86_64-w64-mingw32-gcc >/dev/null || { echo 'Missing mingw-w64 cross compiler' >&2; exit 2; }
cat > "$work/efi.c" <<'EOF'
typedef unsigned long long UINTN;
typedef void *EFI_HANDLE;
typedef struct EFI_SYSTEM_TABLE EFI_SYSTEM_TABLE;
UINTN __attribute__((ms_abi)) efi_main(EFI_HANDLE image, EFI_SYSTEM_TABLE *system) {
  (void)image; (void)system; return 0;
}
EOF
x86_64-w64-mingw32-gcc -nostdlib -Wl,--subsystem,10 -Wl,--entry,efi_main -o "$work/input.efi" "$work/efi.c"
openssl req -new -x509 -newkey rsa:3072 -sha256 -nodes -days 1 \
  -subj '/CN=IDENTIUM disposable test only/' \
  -keyout "$work/key.pem" -out "$work/cert.pem" >/dev/null 2>&1
chmod 600 "$work/key.pem"
bash identium/secureboot.sh sign --image "$work/input.efi" --key "$work/key.pem" \
 --certificate "$work/cert.pem" --output "$work/signed.efi"
bash identium/secureboot.sh verify --image "$work/signed.efi" --certificate "$work/cert.pem"
# Mismatched signer must be rejected.
openssl req -new -x509 -newkey rsa:3072 -sha256 -nodes -days 1 \
 -subj '/CN=Untrusted CI test signer/' -keyout "$work/wrong-key.pem" \
 -out "$work/wrong-cert.pem" >/dev/null 2>&1
if bash identium/secureboot.sh verify --image "$work/signed.efi" --certificate "$work/wrong-cert.pem" >/dev/null 2>&1; then
 echo 'FAIL: untrusted certificate accepted' >&2; exit 1
fi
echo 'PASS: disposable EFI signing, verification and wrong-certificate rejection'
