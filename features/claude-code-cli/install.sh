#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm use --silent default
npm install --global @anthropic-ai/claude-code@latest

# Ensure the native binary is linked even if npm skipped the postinstall script.
claude_dir="$(npm root --global)/@anthropic-ai/claude-code"
if [ -f "$claude_dir/install.cjs" ]; then
  node "$claude_dir/install.cjs"
fi
