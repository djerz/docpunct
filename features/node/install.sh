#!/usr/bin/env bash
set -euo pipefail

nvm_version="v0.40.6"
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -fsSL "$nvm_install_url" | PROFILE=/dev/null bash
fi

# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'
