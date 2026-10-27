# Security policy

IDENT OS is early alpha software. **Do not use it to protect sensitive data or as your primary operating system.** No stable or security-supported release exists yet.

## Reporting vulnerabilities

Please avoid publishing exploit details or sensitive proofs of concept in public GitHub issues.

Use [GitHub's private vulnerability reporting interface](https://github.com/Itsnicbtw/IDENTOS/security/advisories/new) if enabled for this repository. If it is unavailable, contact the maintainers through the repository's listed contact method and request a private reporting channel before sharing details. No guaranteed response time or coordinated-disclosure SLA is offered at this stage.

Include affected commit/version, environment, reproduction steps, impact, and suggested mitigation where possible. Never include real secrets or personal information.

## Supported versions

There are **no security-supported versions** yet. Development images are experimental. Maintainers may prioritise critical security fixes, but patches and timelines are not guaranteed.

## Development security principles

Do not bypass permissions, disable safety checks, or distribute untrusted `.idt` packages as though they were sandboxed. `.idt` v1 checks integrity but does not establish publisher authenticity. Follow [contribution guidelines](CONTRIBUTING.md) for security-sensitive changes.
