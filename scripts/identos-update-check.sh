#!/bin/sh
# Preview available Debian security updates without installing anything.
set -eu
if ! command -v apt-get >/dev/null 2>&1; then echo 'APT unavailable' >&2; exit 2; fi
echo 'IDENT OS update preview (no packages will be installed)'
echo 'Refresh package metadata manually using sudo apt-get update when appropriate.'
apt-get -s upgrade
echo 'Review all proposed changes before upgrading. No rollback or signed IDENT channel is provided yet.'
