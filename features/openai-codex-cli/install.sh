#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm use --silent default
npm install --global @openai/codex
