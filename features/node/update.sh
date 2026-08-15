#!/usr/bin/env bash
set -euo pipefail

nvm_version="v0.40.6"
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

curl -fsSL "$nvm_install_url" | PROFILE=/dev/null bash

# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts --reinstall-packages-from=default
nvm alias default 'lts/*'
