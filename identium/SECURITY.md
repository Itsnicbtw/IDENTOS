# IDENTIUM boot-signing security policy

All keys used in CI are **disposable test keys**, never release keys. Production signing requires offline or hardware-backed key custody and independent review.

The signing helper accepts an existing EFI binary and a local key/certificate; it never enrols firmware keys. `sbverify` checks a signature relative to the supplied certificate, **not whether the firmware trusts that certificate or whether subsequent boot stages are authenticated**.

Before claiming Secure Boot support, test the actual EFI bootloader, kernel/initrd trust chain, forbidden unsigned code, revocation, rollback and recovery in OVMF with Secure Boot enabled, then on explicitly approved devices. Never commit private keys or invoke MOK/NVRAM enrolment automatically.
