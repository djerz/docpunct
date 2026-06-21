#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y gnupg pass pinentry-curses

printf 'GPG tools installed. User-owned key and pass setup is documented in:\n'
printf '  %s/HOWTO.md\n' "$DOCPUNCT_FEATURE_DIR"
