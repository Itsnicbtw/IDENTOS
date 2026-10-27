# Contributing to IDENT OS

IDENT OS is publicly developed. Anyone with a GitHub account can fork the repository and propose changes through a pull request; contributors do not get direct write access to `main`.

## Contribution flow
1. Fork `Itsnicbtw/IDENTOS` and create a branch.
2. Keep commits scoped and explain the technical change.
3. Run `bash scripts/test.sh` locally when your environment supports it.
4. Open a pull request against `main` using the supplied template.
5. GitHub Actions must pass the initramfs build, ISO build, and QEMU serial boot test before changes should be merged.
6. Maintainers review code, licensing, security implications, and documentation.

## Contribution standards
- Do not include secrets, tokens, private user data, or proprietary third-party code.
- State whether changes are tested in QEMU and on what architecture.
- Include test cases for bug fixes and new boot behaviour.
- Keep third-party component notices and licences intact.
- Large architectural changes should start as a GitHub discussion or issue.
- Do not upload large disk images to Git history: CI artifacts are the intended distribution mechanism.

## Security
Do not publish working exploits against current IDENT OS users in a public issue. Contact the repository maintainers privately through the contact method listed on the GitHub profile.

## Project status
The bootable ISO is an experimental developer image. It is not a secure daily-driver, a Windows replacement, or an installer.
