#!/usr/bin/env bash
set -euo pipefail

if command -v uv >/dev/null 2>&1; then
  uv self update || true
else
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

