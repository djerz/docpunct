#!/usr/bin/env bash
set -euo pipefail

nvm_version="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest |
  jq -er '.tag_name | select(test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))')"
nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

curl -fsSL "$nvm_install_url" | PROFILE=/dev/null bash

# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
# Floating aliases (especially lts/*) can point to an uninstalled release.
# Resolve the migration source before installation changes NVM's aliases.
previous_version="$(nvm version default)" || previous_version=""
if [[ ! "$previous_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  previous_version="$(nvm version node)" || previous_version=""
fi

nvm install node
current_version="$(nvm current)"
if [[ "$previous_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ && "$previous_version" != "$current_version" ]]; then
  nvm reinstall-packages "$previous_version"
fi
nvm alias default node
