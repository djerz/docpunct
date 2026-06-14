#!/usr/bin/env bash
set -euo pipefail

if [[ -s "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
fi

rustup update
