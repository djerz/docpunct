#!/usr/bin/env bash
set -euo pipefail

rm -f -- "$HOME/.cargo/bin/neovide"
rm -f -- "$HOME/.local/share/applications/neovide.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

printf 'Left Neovide config, data, and cache directories untouched.\n'
