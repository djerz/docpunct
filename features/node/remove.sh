#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -d "$NVM_DIR" ]]; then
  printf 'Remove nvm manually if desired: %s\n' "$NVM_DIR"
fi

