#!/usr/bin/env bash
set -euo pipefail

if dpkg-query -W obsidian >/dev/null 2>&1; then
  sudo apt-get remove -y obsidian
fi

printf 'Keeping Obsidian configuration and vault data.\n'
