#!/usr/bin/env bash
set -euo pipefail

rm -f -- "$HOME/.cargo/bin/neovide"
rm -f -- "$HOME/.local/share/applications/neovide.desktop"
rm -f -- "$HOME/.local/share/icons/docpunct/neovide.ico"
rmdir --ignore-fail-on-non-empty "$HOME/.local/share/icons/docpunct" 2>/dev/null || true

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache "$HOME/.local/share/icons" >/dev/null 2>&1 || true
fi

printf 'Left Neovide config, data, and cache directories untouched.\n'
