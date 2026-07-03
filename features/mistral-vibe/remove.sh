#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
if uv tool list | awk '$1 == "mistral-vibe" { found = 1 } END { exit !found }'; then
  uv tool uninstall mistral-vibe
fi
