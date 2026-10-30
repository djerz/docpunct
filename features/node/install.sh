#!/usr/bin/env bash
set -euo pipefail

nvm_version="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest |
  jq -er '.tag_name | select(test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))')"
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

curl -fsSL "$nvm_install_url" | PROFILE=/dev/null bash

# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install node
nvm alias default node
