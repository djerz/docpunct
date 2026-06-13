#!/usr/bin/env bash
set -euo pipefail

if command -v git-credential-manager >/dev/null 2>&1; then
  git-credential-manager unconfigure || true
fi

if dpkg-query -W -f='${Status}' gcm 2>/dev/null | grep -q 'install ok installed'; then
  sudo dpkg -r gcm
fi

