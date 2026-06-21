#!/usr/bin/env bash
set -euo pipefail

if command -v git-credential-manager >/dev/null 2>&1; then
  git-credential-manager unconfigure || true
fi

gcm_gpg_marker="$DOCPUNCT_CACHE_DIR/state/installed/gcm-gpg"
if [[ -f "$gcm_gpg_marker" ]]; then
  printf 'Keeping the shared gcm package because gcm-gpg is installed.\n'
elif dpkg-query -W -f='${Status}' gcm 2>/dev/null | grep -q 'install ok installed'; then
  sudo dpkg -r gcm
fi
