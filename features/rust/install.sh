#!/usr/bin/env bash
set -euo pipefail

if [[ -s "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
fi

if command -v rustup >/dev/null 2>&1; then
  rustup update stable
else
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
fi
